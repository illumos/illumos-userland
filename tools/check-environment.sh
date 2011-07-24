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
	ver="`/usr/bin/pkg list -H pkg:/package/pkg | \
		/usr/bin/awk '{print $2}' | /usr/bin/sed 's/.*-//g'`"
	resp="can't determine goodness"

	okver=1.1
	ok=`echo "if ($ver >= $okver) r=1 ; if ($ver < $okver) r=2 ; r" | bc`

	case "$ok" in
		2)
			resp="too old"
			;;
		1)
			resp="ok"
			;;
		*)
			;;
	esac

	echo "pkg version: $ver ... $resp"
}

# check that a given package is installed
_check_pkg()
{
	if pkg list $1 > /dev/null 2> /dev/null ; then
		echo "package $1 ... installed"
	else
		echo "package $1 ... not installed"
	fi
}

# we need all these packages for oi-build
check_pkg_list()
{
	for p in \
		pkg:/archiver/gnu-tar \
		pkg:/compress/p7zip \
		pkg:/compress/unzip \
		pkg:/developer/build/ant \
		pkg:/developer/build/autoconf \
		pkg:/developer/build/automake-110 \
		pkg:/developer/build/gnu-make \
		pkg:/developer/build/libtool \
		pkg:/developer/build/make \
		pkg:/developer/gcc-3 \
		pkg:/developer/gnome/gettext \
		pkg:/developer/java/jdk \
		pkg:/developer/java/junit \
		pkg:/developer/lexer/flex \
		pkg:/developer/macro/cpp \
		pkg:/developer/macro/gnu-m4 \
		pkg:/developer/object-file \
		pkg:/developer/parser/bison \
		pkg:/developer/versioning/mercurial \
		pkg:/file/gnu-coreutils \
		pkg:/file/gnu-findutils \
		pkg:/library/libtool/libltdl \
		pkg:/library/libxslt \
		pkg:/library/pcre \
		pkg:/runtime/perl-512 \
		pkg:/system/library/math/header-math \
		pkg:/text/gawk \
		pkg:/text/gnu-diffutils \
		pkg:/text/gnu-gettext \
		pkg:/text/gnu-grep \
		pkg:/text/gnu-patch \
		pkg:/text/gnu-sed \
		pkg:/text/groff \
		pkg:/text/texinfo \
	; do
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
