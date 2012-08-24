#!/usr/bin/env bash
# git_mirror.sh
#   * mirrors a git repository
#   * usage: git_mirror.sh <branch> <repo> <dir>
# author: Anthony Bargnesi

# check usage
if [ $# != 3 ]; then
    echo "usage: git_mirror.sh <branch> <repo> <absolute path>"
    exit 1
fi 

# check command requirements
NEED_GIT=$(hash git)
if [ $? != 0 ]; then
    echo "error: git command not found"
    exit 1
fi
NEED_SHA=$(hash sha256sum)
if [ $? != 0 ]; then
    echo "error: sha256sum command not found"
    exit 1
fi

# script arguments
BRANCH=$1
REPO=$2
DIR=$3

# helper functions
function create_hash() {
    FILE=$1
    sha256sum $FILE | awk '{print $1}' > $FILE.sha256
}

# create DIR if it doesn't exist
if [ ! -d $DIR ]; then
    mkdir $DIR
fi

# execute git commands from repository, standard behavior
cd $DIR

# clone/hash if repo does not exist
if [ ! -d $DIR/.git ]; then
    echo "`date`: creating $BRANCH of $REPO at $DIR"
    git clone -q $REPO $DIR
    for f in $(find $DIR -type f \( ! -iname 'README.md' -and ! -iname '.git' \)); do
        create_hash $f
    done
# fetch, diff, pull, then hash if repo does exist
else
    echo "`date`: updating $BRANCH of $REPO at $DIR"
    git fetch -q origin
    DIFF_FILES=$(git diff ..@{u} --name-only)
    if [ -n "$DIFF_FILES" ]; then
        git pull -q origin $BRANCH
        for f in $DIFF_FILES; do
            create_hash $f
        done
    fi
fi

