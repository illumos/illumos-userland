#!/bin/sh

# check the os version
check_os_ver()
{
	ver="`uname -v`"
	oiver=""
	resp="can't determine goodness"

	case "$ver" in
		oi_*)
			oiver=`echo $ver | sed -e 's/^oi_//'`
			;;
		*)
			;;
	esac

	case "$oiver" in
		[0-9][0-9][0-9])
			resp="too old"
			[ "$oiver" -ge 151 ] && resp="ok"
			;;
		*)
			;;
	esac

	echo "OS version: $ver ... $resp"
}

# check the studio version for a given path
_studio_ver()
{
	ver="`"$1/bin/version" | grep '^Sun Studio [0-9]\+'`"
	resp="can't determine goodness"

	case "$ver" in
		"Sun Studio 12 update 1")
			resp="ok"
			;;
		*)
			;;
	esac

	echo "Sun Studio version: $ver ... $resp"
}

# find the right path for studio
check_studio()
{
	for p in /opt/SUNWspro /opt/sunstudio12.1 ; do
		[ ! -x "$p/bin/version" ] && continue

		echo "Sun Studio found ... $p"
		_studio_ver "$p"
		return 0
	done

	echo "Sun Studio not found, skipping version check"
}

# is pkg the right version?
check_pkg_ver()
{
	ver="`pkg list pkg://openindiana.org/package/pkg | awk \
		'BEGIN{SKIP=1}(SKIP==1){SKIP=0;next}{print $2}'`"
	resp="can't determine goodness"

	case "$ver" in
		0.5.11-0.*)
			pkgver="`echo $ver | cut -d- -f2 | cut -d. -f2`"
			;;
		*)
			;;
	esac

	case "$pkgver" in
		[0-9][0-9][0-9])
			resp="too old"
			[ "$pkgver" -ge 151 ] && resp="ok"
			;;
		*)
			;;
	esac

	echo "pkg version: $ver ... $resp"
}

# check that a given package is installed
_check_pkg()
{
	if pkg list pkg://openindiana.org/$1 > /dev/null 2> /dev/null ; then
		echo "package $1 ... installed"
	else
		echo "package $1 ... not installed"
	fi
}

# we need all these packages for oi-build
check_pkg_list()
{
	for p in developer/versioning/mercurial developer/build/ant developer/gcc-3 \
		system/library/math/header-math developer/build/gnu-make \
		developer/build/libtool developer/build/autoconf \
		developer/build/automake-110 library/libtool/libltdl \
		archiver/gnu-tar compress/p7zip compress/unzip \
		developer/gnome/gettext developer/lexer/flex \
		developer/build/make developer/parser/bison \
		developer/macro/gnu-m4 developer/object-file \
		developer/macro/cpp file/gnu-coreutils file/gnu-findutils \
		library/libxslt library/pcre text/gawk text/gnu-diffutils \
		text/gnu-gettext text/gnu-grep text/gnu-patch text/gnu-sed \
		text/groff text/texinfo developer/java/jdk \
		developer/java/junit ; do
		_check_pkg $p
	done
}

check_os_ver
check_studio

pkg_path="`which pkg`"
if [ -z "$pkg_path" ]; then
	echo "pkg not found, skipping pkg related checks"
	exit 0
fi

echo "pkg found ... $pkg_path"
check_pkg_ver
check_pkg_list
