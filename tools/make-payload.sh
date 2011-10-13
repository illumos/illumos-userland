#!/bin/sh

set -e
set -u

usage() {
    echo "$0 [directory]"
    exit 1
}

if [ $# = 1 ]; then
    cd "$1" || usage
elif [ $# != 0 ]; then
    usage
fi

gfind * -type d -printf 'dir path=%p\n'
gfind * -type f -printf 'file path=%p\n'
gfind * -type l -printf 'link path=%p target=%l\n'

exit 0

