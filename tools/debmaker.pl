#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use integer;
use Data::Dumper;
use Getopt::Long qw(:config no_ignore_case);
use File::Copy;
use Text::Wrap;
use File::Basename;
use Cwd;
use POSIX qw(strftime);

sub blab {
    print 'debmaker: ', @_, "\n";
}
sub warning {
    blab 'WARNING: ', @_;
    sleep 2;
}
sub fatal {
    blab 'FATAL: ', @_;
    exit 1;
}
sub my_chdir {
    my ($path) = @_;
    chdir $path or fatal "Can't chdir() to `$path': $!";
}
sub my_symlink {
    my ($src, $dst) = @_;
    symlink $src, $dst
        or fatal "Can't create symlink `$src' -> `$dst': $!"
}
sub my_hardlink {
    my ($src, $dst) = @_;

    # For harlink creating target file must be accessible:
    my $pwd = getcwd;
    my $dir = dirname $dst;
    my_chdir $dir;
    link $src, $dst
        or fatal "Can't create hardlink `$src' -> `$dst': $!";
    my_chdir $pwd;
}
sub my_copy {
    my ($src, $dst) = @_;
    copy $src, $dst
        or fatal "Can't copy `$src' to `$dst': $!";
}
sub my_chown {
    my ($u, $g, $path) = @_;
    my $uid = getpwnam $u;
    my $gid = getgrnam $g;
    chown $uid, $gid, $path
         or fatal "Can't chown ($u.$g) `$path': $!";
}
sub my_chmod {
    my ($mode, $path) = @_;
    chmod oct($mode), $path
        or fatal "Can't chmod ($mode) `$path': $!";
}
sub my_mkdir {
    my ($path, $mode) = @_;
    if (defined $mode) {
        mkdir $path, oct($mode)
            or fatal "Can't create dir `$path' with mode `$mode': $!";
    } else{
        mkdir $path
            or fatal "Can't create dir `$path': $!";
    }
}
sub uniq {
    my ($array_ref) = @_;
    my %hash = map { $_, 1 } @$array_ref;
    @$array_ref = keys %hash;
}

sub shell_exec {
    my ($cmd) = @_;
    blab "executing `$cmd'";
    system($cmd);
    if ($? == -1) {
        fatal "failed to execute: $!";
    } elsif ($? & 127) {
        fatal (printf "child died with signal %d, %s coredump",
            ($? & 127),  ($? & 128) ? 'with' : 'without')
    } else {
        my $rc = $? >> 8;
        if ($rc != 0) {
            warning "child exited with value $rc";
        }
    }
}
sub get_command_line {
    my ($map_ref, $hash_ref) = @_;
    my $res = '';
    foreach my $k (keys %$map_ref) {
        $res .= " $$map_ref{$k} '$$hash_ref{$k}'" if exists $$hash_ref{$k};
    }
    return $res;
}
sub write_file {
    my ($filename, $content) = @_;
    blab "Writing file `$filename'";
    if (open FD, '>', $filename) {
        print FD $content;
        close FD;
    } else {
        fatal "Can't write to file `$filename': $!"
    }
}
sub write_script {
    my ($filename, $content) = @_;
    $content = "#!/bin/sh\nset -e\n$content";
    write_file $filename, $content;
    my_chmod '0555', $filename;
}

sub get_output {
    my ($cmd) = @_;
    if (open OUT, "$cmd |") {
        my @lines = <OUT>;
        close OUT;
        chomp @lines;
        warning "Empty output from `$cmd'" unless @lines;
        return \@lines;
    } else {
        fatal "Can't execute `$cmd': $!"
    }
}
sub get_output_line {
    return (@{get_output @_})[0];
}

sub trim {
    # works with refs:
    $$_ =~ s/^\s*(.*)\s*$/$1/ foreach @_;
}


# Expected input for @PROTO_DIRS:
# -d /root/oi-build/components/elinks/build/prototype/i386/mangled
# -d /root/oi-build/components/elinks/build/prototype/i386
# -d .
# -d /root/oi-build/components/elinks
# -d elinks-0.11.7
# (like debian/tmp)
my @PROTO_DIRS = ();

# Where to create debs prototypes
# (like debian/pkg-name)
my $DEBS_DIR = '';

# If true, will use manifests from command line
# to resolve dependencies:
my $BOOTSTRAP = 0;

my $MAINTAINER = 'Nexenta Systems <maintainer@nexenta.com>';
my $VERSION = '0.0.0';
my $ARCH = 'solaris-i386';
my $SOURCE = 'xxx'; # only for *.changes
my $DISTRIB = 'unstable'; # only for *.changes

# Mapping file => IPS FMRI, filled on bootstrap:
my %PATHS = ();

GetOptions (
    'd=s' => \@PROTO_DIRS,
    'D=s' => \$DEBS_DIR,
    'V=s' => \$VERSION,
    'A=s' => \$ARCH,
    'M=s' => \$MAINTAINER,
    'S=s' => \$SOURCE,
    'N=s' => \$DISTRIB,
    'bootstrap!' => \$BOOTSTRAP,
    'help|h' => sub {usage()},
) or usage();

sub usage {
    print <<USAGE;
Usage: $0 [options] -D <output dir> -d <proto dir> [-d <proto dir> ... ] manifests

Options:

    -d <proto dir>     where to find files (like debian/tmp)

    -D <output dir>    where to create package structure and debs,
                       <output dir>/pkg-name and
                       <output dir>/pkg-name*.deb will be created

    -V <version>       version of created packages (default is `$VERSION'),
                       may be 'ips' to use the same as for IPS system.

    -A <architecture>  package architecture, default is `$ARCH'

    -S <source name>   package source name to make reprepro happy
                       with *.changes files, default is `$SOURCE'

    -N <dist name>     distribution  name to make reprepro happy
                       with *.changes files, default is `$DISTRIB'

    -M <maintainer>    Package maintainer - mandatory for debs,
                       default is `$MAINTAINER'
   
    --bootstrap        Search for dependencies within listed manifests,
                       not within installed system (for bootstraping)
                       ** not implemented yet **

    -h, --help         Show help info

USAGE
    exit 1;
}

sub parse_keys {
    my ($line) = @_;
    # parse:
    # name=pkg.summary value="advanced text-mode WWW browser"
    # into:
    # 'name' => pkg.summary
    # 'value' => "advanced text-mode WWW browser"
    # http://stackoverflow.com/questions/168171/regular-expression-for-parsing-name-value-pairs
    # TODO: add support for dublicates: dir=dir1 dir=dir2
    my %pairs = ($line =~ m/((?:\\.|[^= ]+)*)=("(?:\\.|[^"\\]+)*"|(?:\\.|[^ "\\]+)*)/g);
    foreach my $k (keys %pairs) {
        $pairs{$k} =~ s/^"(.+)"$/$1/;
    }
    return \%pairs;
}

sub read_manifest {
    my ($filename) = @_;
    my %data = ();
    $data{'dir'} = [];
    $data{'file'} = [];
    $data{'link'} = [];
    $data{'hardlink'} = [];
    $data{'depend'} = [];
    $data{'legacy'} = [];
    $data{'group'} = [];
    $data{'user'} = [];
    $data{'license'} = [];

    if (open IN, '<', $filename) {
        while (<IN>) {
            study; chomp;
            if (/^set +/) {
                my $pairs = parse_keys $_;
                $data{$$pairs{'name'}} = $$pairs{'value'};
            } elsif (/^dir +/) {
                my $pairs = parse_keys $_;
                push @{$data{'dir'}}, $pairs;
            } elsif (/^file +(\S+) +/) {
                my $maybe_src = $1;
                my $pairs = parse_keys $_;
                $$pairs{'src'} = $maybe_src if $maybe_src ne 'NOHASH';
                push @{$data{'file'}}, $pairs;
            } elsif (/^link +/) {
                my $pairs = parse_keys $_;
                push @{$data{'link'}}, $pairs;
            } elsif (/^hardlink +/) {
                my $pairs = parse_keys $_;
                push @{$data{'hardlink'}}, $pairs;
            } elsif (/^depend +/) {
                my $pairs = parse_keys $_;
                push @{$data{'depend'}}, $pairs;
            } elsif (/^legacy +/) {
                my $pairs = parse_keys $_;
                push @{$data{'legacy'}}, $pairs;
            } elsif (/^group +/) {
                my $pairs = parse_keys $_;
                push @{$data{'group'}}, $pairs;
            } elsif (/^user +/) {
                my $pairs = parse_keys $_;
                push @{$data{'user'}}, $pairs;
            } elsif (/^license +(\S+) +/) {
                my $maybe_src = $1;
                my $pairs = parse_keys $_;
                $$pairs{'src'} = $maybe_src if $maybe_src !~ /=/;
                push @{$data{'license'}}, $pairs;
            } elsif (/^\s*$/) {
                # Skip empty lines
            } elsif (/^\s*#/) {
                # Skip comments
            } else {
                warning "Unknown action: `$_'";
            }
            # TODO:
            # user - to create users (in postinstall?)
            # restart_fmri - restart SMF
        }
        close IN;
        return \%data;
    } else {
        fatal "Can't open `$filename': $!";
    }
}

sub get_debpkg_names {
#    pkg:/web/browser/elinks@0.11.7,5.11-1.1
# => web-browser-elinks
#        browser-elinks
#                elinks
    my ($fmri) = @_;
    my @names = ();
    if ($fmri =~ m,^(?:pkg:/)?([^@]+)(?:@.+)?$,) {
        my $pkg = $1;
        my @parts = split /\//, $pkg;
        while (@parts) {
            push @names, (join '-', @parts);
            shift @parts;
        }
        return @names;
    } else {
        fatal "Can't parse FMRI to get dpkg name: `$fmri'";
    }
}

sub get_ips_version {
#    pkg:/web/browser/elinks@0.11.7,5.11-1.1
# => 0.11.5-5.11-1.1
    my ($fmri) = @_;
    if ($fmri =~ m,^(?:pkg:/)?[^@]+@(.+)$,) {
        my $ips = $1;
        $ips =~ s/[,:]/-/g;
        return $ips;
    } else {
        fatal "Can't parse FMRI to get IPS version: `$fmri'";
    }
}

sub get_pkg_section {
    my ($pkgname) = @_;
    if ($pkgname =~ m,^([^-@]+)-.*,) {
        return (split /-/, $pkgname)[0];
    } elsif ($pkgname =~ m,^pkg:/([^/]+)/.*,) {
        return $1;
    } else {
        fatal "Can't get section for package `$pkgname'"
    }
}

sub get_dir_size {
    my ($path) = @_;
    # We get size just after files are copied
    # and need sync() to get proper sizes:
    my $out = get_output("sync && du -sk $path | cut -f 1");
    return $$out[0];
}

sub find_pkgs_with_paths {
    my @paths = @_;
    s,^/+,,g foreach @paths;
    my $dpkg = get_output('dpkg-query --search -- ' . join(' ',  @paths) . ' | cut -d: -f1');
    return $dpkg;
}

sub guess_required_deps {
    my ($path) = @_;
    my $elfs = get_output("find $path -type f -exec file {} \\; | grep ELF | cut -d: -f1");
    my @deps = ();
    if (@$elfs) {
    #   my $libs = get_output('ldd ' . join(' ', @$elfs) . ' | grep "=>"');
        my $libs = get_output('elfdump -d ' . join(' ', @$elfs) . ' | grep NEEDED | awk \'{print $4}\'');
        uniq $libs;
        my $pkgs = find_pkgs_with_paths @$libs;
        push @deps, @$pkgs;
    }
    return \@deps;
}


if (!$DEBS_DIR) {
    fatal "Output dir is not set. Use -D option."
}
if (! -d $DEBS_DIR) {
    fatal "Not a directory: `$DEBS_DIR'"
}

# Walk through all manifests
# and collect files, symlinks, hardlink
# mapping them to package names:
if ($BOOTSTRAP) {
    blab "Bootstrap: collecting paths ...";
    foreach my $manifest_file (@ARGV) {
        my $manifest_data = read_manifest $manifest_file;
        my $fmri = $$manifest_data{'pkg.fmri'};
        my @items = ();
        if (my @files = @{$$manifest_data{'file'}}) {
            push @items, @files;
        }
        if (my @symlinks = @{$$manifest_data{'link'}}) {
            push @items, @symlinks;
        }
        if (my @hardlinks = @{$$manifest_data{'hardlink'}}) {
            push @items, @hardlinks;
        }
        foreach my $item (@items) {
            my $path = $$item{'path'};
            if (exists $PATHS{$path}) {
                warning "`$path' already present in `$PATHS{$path}' and now found in `$fmri' (manifest `$manifest_file')"
            } else {
                $PATHS{$path} = $fmri;
            }
        }
    }
    blab 'Bootstrap: ' . (keys %PATHS) . ' known paths'
}


my %changes = ();
$changes{'Date'} = strftime '%a, %d %b %Y %T %z', localtime; # Sat, 11 Jun 2011 17:08:17 +0200
$changes{'Architecture'} = $ARCH;
$changes{'Format'} = '1.8';
$changes{'Maintainer'} = $MAINTAINER;
$changes{'Source'} = lc $SOURCE;
$changes{'Version'} = $VERSION;
$changes{'Distribution'} = $DISTRIB;
$changes{'Changes'} = 'Everything has changed';
$changes{'Description'} = '';
$changes{'Checksums-Sha1'} = '';
$changes{'Checksums-Sha256'} = '';
$changes{'Files'} = '';
$changes{'Binary'} = '';


foreach my $manifest_file (@ARGV) {
    blab "****** Manifest: `$manifest_file'";
    my $manifest_data = read_manifest $manifest_file;
    my @provides = get_debpkg_names $$manifest_data{'pkg.fmri'};
    my $debname = shift @provides; # main name (web-browser-elinks)
    my $debsection = get_pkg_section $debname;
    my $debpriority = exists $$manifest_data{'pkg.priority'} ?  $$manifest_data{'pkg.priority'} : 'optional';

    foreach my $l (@{$$manifest_data{'legacy'}}) {
        push @provides, $$l{'pkg'};
    }
    my $provides_str = join(', ', @provides);
    my $pkgdir = "$DEBS_DIR/$debname";
    blab "Main package name: $debname";
    blab "Other names: $provides_str";

    my $ipsversion = get_ips_version $$manifest_data{'pkg.fmri'};
    my $debversion = undef;
    if ($VERSION eq 'ips') {
        blab "Using IPS version scheme: $ipsversion";
        $debversion = $ipsversion;
    } else {
        blab "Using given version: $VERSION";
        $debversion = $VERSION;
    }

    # Make sure to work with empty tree:
    # mkdir will fail if dir exists
    my_mkdir $pkgdir;

    # Believe that dirs are listed in proper order:
    # usr, usr/bin, etc
    if (my @dirs = @{$$manifest_data{'dir'}}) {
        blab "Making dirs ...";
        foreach my $dir (@dirs) {
            my $dir_name = "$pkgdir/$$dir{'path'}";
            my_mkdir $dir_name, $$dir{'mode'};
            my_chown $$dir{'owner'}, $$dir{'group'}, $dir_name;
        }
    }

    my @conffiles = ();
    if (my @files = @{$$manifest_data{'file'}}) {
        blab "Copying files ...";
        foreach my $file (@files) {
            my $dst = "$pkgdir/$$file{'path'}";
            my $src = exists $$file{'src'} ? $$file{'src'} : $$file{'path'};
            # find $src in @PROTO_DIRS:
            my $src_dir = undef;
            foreach my $d (@PROTO_DIRS) {
                # http://stackoverflow.com/questions/2238576/what-is-the-default-scope-of-foreach-loop-in-perl
                $src_dir = $d;
                last if -f "$src_dir/$src";
            }
            fatal "file `$src' not found in ", join(', ', @PROTO_DIRS)
                unless $src_dir;

            $src = "$src_dir/$src";
            my_copy $src, $dst;
            my_chown $$file{'owner'}, $$file{'group'}, $dst;
            my_chmod $$file{'mode'}, $dst;

            push @conffiles, $$file{'path'} if exists $$file{'preserve'};
        }
    }

    if (my @hardlinks = @{$$manifest_data{'hardlink'}}) {
        blab "Creating hardlinks ...";
        foreach my $link (@hardlinks) {
            my_hardlink $$link{'target'}, "$pkgdir/$$link{'path'}";
        }
    }
    if (my @symlinks = @{$$manifest_data{'link'}}) {
        blab "Creating symlinks ...";
        foreach my $link (@symlinks) {
            my_symlink $$link{'target'}, "$pkgdir/$$link{'path'}";
        }
    }

    if (my @license = @{$$manifest_data{'license'}}) {
        # FIXME: install in usr/share/doc/<pkg>/copyright
        # what are the owner, permissions?
        # multiple licenses?
    }
    my $installed_size = get_dir_size($pkgdir);

    my @depends = ();
    my @predepends = ();
    my @recommends = ();
    my @conflicts = ();
    blab "Getting dependencies ...";
    foreach my $dep (@{$$manifest_data{'depend'}}) {
        if ($$dep{'fmri'} ne '__TBD') {
            my $dep_pkg = (get_debpkg_names($$dep{'fmri'}))[0];
            blab "Dependency: $dep_pkg ($$dep{'type'})";
            push @depends,    $dep_pkg if $$dep{'type'} eq 'require';
            push @predepends, $dep_pkg if $$dep{'type'} eq 'origin';
            # push @recommends, $dep_pkg if $$dep{'type'} eq 'optional';
            push @conflicts,  $dep_pkg if $$dep{'type'} eq 'exclude';
        }
    }
    push @depends, @{guess_required_deps($pkgdir)};

    uniq \@depends;
    # When a program and a library are in the same package:
    @depends = grep {$_ ne $debname} @depends;
    uniq \@predepends;
    uniq \@recommends;
    uniq \@conflicts;


    my $control = '';
    $control .= "Package: $debname\n";
    $control .= "Source: $changes{Source}\n";
    $control .= "Version: $debversion\n";
    $control .= "Section: $debsection\n";
    $control .= "Priority: $debpriority\n";
    $control .= "Maintainer: $MAINTAINER\n";
    $control .= "Architecture: $ARCH\n";

    $control .= "Description: $$manifest_data{'pkg.summary'}\n";
    $changes{'Description'} .= "\n $debname - $$manifest_data{'pkg.summary'}";

    $control .= wrap(' ', ' ', $$manifest_data{'pkg.description'}) . "\n"
        if exists $$manifest_data{'pkg.description'};

    $control .= "Provides: $provides_str\n";
    $control .= 'Depends: ' . join(', ', @depends) . "\n" if @depends;
    $control .= 'Pre-Depends: ' . join(', ', @predepends) . "\n" if @predepends;
    $control .= 'Recommends: ' . join(', ', @recommends) . "\n" if @recommends;
    $control .= 'Conflicts: ' . join(', ', @conflicts) . "\n" if @conflicts;
    $control .= "Installed-Size: $installed_size\n";

    $control .= "Origin: $$manifest_data{'info.upstream_url'}\n"
        if exists $$manifest_data{'info.upstream_url'};
    $control .= "X-Source-URL: $$manifest_data{'info.source_url'}\n"
        if exists $$manifest_data{'info.source_url'};
    $control .= "X-FMRI: $$manifest_data{'pkg.fmri'}\n";

    my_mkdir "$pkgdir/DEBIAN";

    write_file "$pkgdir/DEBIAN/control", $control;

    if (@conffiles) {
       write_file "$pkgdir/DEBIAN/conffiles", (join "\n", @conffiles);
    }


    my $preinst = '';
    my $postinst = '';
    my $prerm = '';
    my $postrm = '';
    if (my @groups = @{$$manifest_data{'group'}}) {
        foreach my $g (@groups) {
            my $cmd = "if ! getent group $$g{'groupname'} >/dev/null; then\n";
            $cmd .= "echo Adding group $$g{'groupname'}\n";
            $cmd .= 'groupadd';
            $cmd .= get_command_line {
                'gid' => '-g'
                }, $g;
            $cmd .= " $$g{'groupname'} || true\n";
            $cmd .= "fi\n";
            $preinst .= $cmd;
        }
    }
    if (my @users = @{$$manifest_data{'user'}}) {
        foreach my $u (@users) {
            my $cmd = "if ! getent passwd $$u{'username'} >/dev/null; then\n";
            $cmd .= "echo Adding user $$u{'username'}\n";
            $cmd .= 'useradd';
            $cmd .= get_command_line {
                'uid' => '-u',
                'group' => '-g',
                'gcos-field' => '-c',
                'home-dir' => '-d',
                'uid' => '-u',
                'login-shell' => '-s',
                'group-list' => '-G',
                'inactive' => '-f',
                'expire' => '-e',
                }, $u;
            $cmd .= " $$u{'username'} || true\n";
            $cmd .= "fi\n";
            $preinst .= $cmd;
        }
    }

    write_script "$pkgdir/DEBIAN/preinst", $preinst if $preinst;

    my $pkg_deb = "${pkgdir}_${debversion}_${ARCH}.deb";
    # FIXME: we need GNU tar
    shell_exec(qq|PATH=/usr/gnu/bin:/usr/bin dpkg-deb -b "$pkgdir" "$pkg_deb"|);

    my $sha1   = get_output_line "sha1sum $pkg_deb | cut -d' ' -f1";
    my $sha256 = get_output_line "sha256sum $pkg_deb | cut -d' ' -f1";
    my $md5sum = get_output_line "md5sum $pkg_deb | cut -d' ' -f1";
    my $size   = (stat $pkg_deb)[7];
    my $pkg_deb_base = basename $pkg_deb;

    $changes{'Checksums-Sha1'} .= "\n $sha1 $size $pkg_deb_base";
    $changes{'Checksums-Sha256'} .= "\n $sha256 $size $pkg_deb_base";
    $changes{'Files'} .= "\n $md5sum $size $debsection $debpriority $pkg_deb_base";
    $changes{'Binary'} .= " $debname";
}

my $changes_cnt = join "\n", map {"$_: $changes{$_}"} sort keys %changes;
write_file "$DEBS_DIR/$changes{'Source'}.changes", $changes_cnt;

