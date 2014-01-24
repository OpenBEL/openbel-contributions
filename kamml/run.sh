#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${DIR}" || exit 1

if [ $# -ne 2 ]; then
    ant run
    echo
    echo "Usage: $0 KAM FILE"
    exit 1
fi

ant -DKAM="$1" -DFILE="$2" run

