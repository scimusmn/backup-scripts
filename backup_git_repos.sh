#!/usr/bin/env sh

############################################################
# backup_git_repos.sh
#
# Backup all of the bare git repos in a central directory.
# - Make a bare clone of each git repo
# - Compress it
# - Move it to the a folder for remote rsync'ing
############################################################

TAR="$(which tar)"
ECHO="$(which $ECHO)"
GIT="$(which git)"

# Usage description
usage ()
{
cat << EOF
USAGE: $0 arguments

This script makes a compressed backup of all git repos in
a central directory.

ARGUMENTS:
   ?   Display this help.

  -s   Source directory, where your git repos are stored.
  -d   Backup destination directory.
  -u   Git username
  -h   Git servername

EOF
}

# Get the command line arguments.
while getopts ":s:d:u:h:" opt ; do
  case $opt in
    s ) REPOS_SOURCE=$OPTARG ;;
    d ) BACKUP_DEST=$OPTARG ;;
    u ) GIT_USERNAME=$OPTARG ;;
    h ) GIT_HOST=$OPTARG ;;

    * ) $ECHO \n $usage
      exit 1 ;;
  esac
done

# Make sure all arguments are specified.
if ( [ -z "$REPOS_SOURCE" ] || [ -z "$BACKUP_DEST" ] || [ -z "$GIT_USERNAME" ] || [ -z "$GIT_HOST" ] ) ; then
  $ECHO ERROR: "You must supply all arguments."
  usage
  exit 1
fi

# Make sure the backup destination exits.
if [ ! -d $BACKUP_DEST ] ; then
  $ECHO ERROR: "The backup destination is not a valid directory."
  usage
  exit 1
fi

# Build array of git repos in the backup directory
if [ -d "$REPOS_SOURCE" ]; then
  for repo in $( find $REPOS_SOURCE -type f -name '*.git' )
  do
    $ECHO -e "CLONING "$repo"\r"
    $GIT clone --bare $GIT_USERNAME@$GIT_HOST:$repo $BACKUP_DEST/$repo
    $ECHO -e "COMPRESSING "$repo"\r"
    $TAR vczf $BACKUP_DEST/$repo.tgz -C $BACKUP_DEST $repo
    # Delete the cloned
    # rm -rf $dest
  done
fi
