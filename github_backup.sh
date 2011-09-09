#!/usr/bin/env sh
############################################################
# github_backup.sh
#
# A script to backup all repos in a GitHub organization
#
# Inspiration from:
# http://www.splitbrain.org/blog/2010-12/14-github_mirror
############################################################

GZIP="$(which gzip)"
ECHO="$(which echo)"
API_URL=https://api.github.com/
ORG=scimusmn

# Usage description
usage ()
{
cat << EOF
USAGE: $0 arguments

This script creates local clones of all repos in a GitHub organization
and keeps them in sync.

ARGUMENTS:
   ?   Display this help.

       REQUIRED ARGUMENTS
  -u   GitHub username
  -p   GitHub password
  -d   Destination

EOF
}

# Get the command line arguments.
while getopts ":u:p:a:d:" opt ; do
  case $opt in
    u ) USER=$OPTARG ;;
    p ) PASS=$OPTARG ;;
    d ) DEST=$OPTARG ;;

    * ) $ECHO \n $usage
      exit 1 ;;
  esac
done

# Make sure the user has specified all the required attributes
if ( [ -z "$USER" ] || [ -z "$PASS" ] || [ -z "$DEST" ] ) ; then
  $ECHO ERROR: "You must specify a username, password, and GitHub API token."
  usage
  exit 1
fi

# the API returns only 30 repos per page, let's check the first 10 pages

# Parse the JSON using grep
# A bit dirty, but it works
repos="$(curl -u "${USER}:${PASS}" ${API_URL}orgs/$ORG/repos | grep -Po '\"name\":.*?\",' | sed -n 's/.*\"\(.*\)\".*/\1/p')"
for repo in $repos
do

  repo=${repo}.git
  repo_address="git@github.com:$ORG/$repo"
  echo "============================================================"
  if [ -d $DEST/$repo ] ; then
    echo "Fetching changes from $repo"
    cd $DEST/$repo
    # Fetch any changes
    git fetch -q
  else
    echo "Creating a fresh mirror of $repo"
    git clone --mirror $repo_address $DEST/$repo
  fi
done

#repos=''
#for i in `seq 1 10`
#do
    #rep="$(wget --quiet --post-data="login=${USER}&token=${API_TOKEN}" -O - ${API_URL}/repos/show/${USER}?page=$i | xmlstarlet sel -T -t -m '//repository' -v name -o ' ')"
    #repos="$repos $rep"
#done

#[[ ! -d ${DEST} ]] && mkdir -p ${DEST}
#cd ${DEST}

#for repo in $repos;
#do
  #$ECHO $repo
    #branches="$(wget --quiet --post-data="login=${USER}&token=${API_TOKEN}" -O - ${API_URL}/repos/show/${USER}/${repo}/branches | xmlstarlet sel -T -t -m '//branches/*' -v 'name()' -o ' ')"

    #if [ ! -d ${repo} ]; then
        #git clone -o github git@github.com:${USER}/${repo}.git ${repo}
    #fi

    #cd ${repo}
    #for branch in $branches;
    #do
        #git branch --track ${branch} github/${branch} 2>/dev/null
        #git checkout ${branch}
        #git pull github ${branch}
    #done
    #cd ${DEST}
#done

