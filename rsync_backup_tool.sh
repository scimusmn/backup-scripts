#!/usr/bin/env sh

############################################################
# rsync_backup_tool.sh
#
# Makes a rsync backup and manages hourly, daily, weekly,
# and monthly snapshots of that backup.
#
# This script is designed to be run hourly, by a cron process.
#
# Inspiration from:
# https://github.com/Gestas/Tarsnap-generations/blob/master/tarsnap-generations.sh
# http://www.mikerubel.org/computers/rsync_snapshots
# https://help.ubuntu.com/8.04/serverguide/C/backups-shellscripts-rotation.html
############################################################

# When should we make the daily backup - 24 hour time
DAILY_TIME=10
#DAILY_TIME=03
# When should we make the weekly backup - Sunday(7)
WEEKLY_DAY=6

usage ()
{
cat << EOF
USAGE: $0 arguments

This script makes and archives rsync backups.
It is designed to be run repeatedly by a cron process.

ARGUMENTS:
   ?   Display this help.

       DEFINE EITHER -r OR -l
  -r   Remote backup source
       Example:
       username@server.name.com:/path/to/backup/source
  -l   Local backup source
       Example:
       /path/to/local/backup/source

  -t   Backup destination path. Rsync and snapshot archives
       will be stored here.

  -n   A descriptive filename for the backup (no spaces)
       Example:
       apache_config
  -h   Number of hourly backups to retain.
  -d   Number of daily backups to retain.
  -w   Number of weekly backups to retain.
  -m   Number of monthly backups to retain.

EOF
}

# Get the command line arguments.
while getopts ":r:l:t:n:h:d:w:m:" opt ; do
  case $opt in
    r ) REMOTE_SOURCE=$OPTARG ;;
    l ) LOCAL_SOURCE_PATH=$OPTARG ;;
    t ) DEST_PATH=$OPTARG ;;

    # We add one here to delete the file that is one older
    # than the max count.
    n ) ARCHIVE_NAME=$OPTARG ;;
    h ) HOURLY_COUNT=$(($OPTARG+1)) ;;
    d ) DAILY_COUNT=$(($OPTARG+1)) ;;
    w ) WEEKLY_COUNT=$(($OPTARG+1)) ;;
    m ) MONTHLY_COUNT=$(($OPTARG+1)) ;;

    * ) echo \n $usage
      exit 1 ;;
  esac
done

# Make sure the user has specified at least one backup source
if ( [ -z "$REMOTE_SOURCE" ] && [ -z "$LOCAL_SOURCE_PATH" ] ) ; then
  echo ERROR: "You must specify either a remote or local source -r or -l"
  usage
  exit 1
fi

# Make sure the user hasn't specified two backup sources
if ( [ "$REMOTE_SOURCE" ] && [ "$LOCAL_SOURCE_PATH" ] ) ; then
  echo ERROR: "You must specify either a remote or local source -r or -l. Not both."
  usage
  exit 1
fi

# Check for required arguments
if ( [ -z "$DEST_PATH" ] || [ -z $ARCHIVE_NAME ] || [ -z "$HOURLY_COUNT" ] || [ -z "$DAILY_COUNT" ] || [ -z "$WEEKLY_COUNT" ] || [ -z "$MONTHLY_COUNT" ] )
then
  echo ERROR: "-t, -n, -h, -d, -w, -m are not optional.\n"
  usage
  exit 1
fi

############################################################
# rsync files with local backup
############################################################
echo 'Syncing the backup with the server'

# rsync the files with these possible options
#   -a (archive) Tells rsync to copy over, times, groups, symlinks, and traverses directories
#   -v (verbose)
#   -z (compress) Use compression in the transfer
#   -P (partial and progress) Save partially transfered files, and show transfer progress
#   -e ssh Use SSH to do the transfer
if [ "$REMOTE_SOURCE" ] ; then
  rsync -avz -P -e ssh $REMOTE_SOURCE $DEST_PATH
  # Get the name of the local folder where the rsync'ed files live
  # This is used when we archive this later.
  RSYNC_FOLDER=${REMOTE_SOURCE##*/}
elif [ "$LOCAL_SOURCE_PATH" ] ; then
  rsync -avz -P $LOCAL_SOURCE_PATH $DEST_PATH
  RSYNC_FOLDER=${LOCAL_SOURCE_PATH##*/}
fi

############################################################
# Create grandfather, father, son snapshots
############################################################
echo 'Creating a snapshot of the backup.'
# Current date
DOM=$(date +%d)

# Current day of the week
DOW=$(date +%u)

# The last day of this month
LAST_DOM=$(echo $(cal) | awk '{print $NF}')

# Current time, stored as a constant so we can use it at several points in the script
DATE_STRING='+%Y_%m_%d_%H'
NOW=$(date $DATE_STRING)
CUR_HOUR=$(date +%H)

# Determine the backup type
# Only do daily, weekly, and monthly backups at the daily backup time
# Otherwise default to hourly
BAK_TYPE=HOURLY
if ( [ "$DOM" = "$LAST_DOM" ] && [ "$CUR_HOUR" = "$DAILY_TIME" ] ) ; then
  BAK_TYPE=MONTHLY
else
  if ( [ "$DOW" = "$WEEKLY_DAY" ] && [ "$CUR_HOUR" = "$DAILY_TIME" ] ) ; then
    BAK_TYPE=WEEKLY
  else
    if [ "$CUR_HOUR" = "$DAILY_TIME" ] ; then
      BAK_TYPE=DAILY
    fi
  fi
fi

# Create archive
tar czvf ${DEST_PATH}/${ARCHIVE_NAME}_${NOW}_${BAK_TYPE}.tgz $DEST_PATH/$RSYNC_FOLDER

############################################################
# Delete old snapshots
############################################################

# Create the matching date strings X , days, weeks, months back
HOURLY_DELETE_TIME=$(date -v-${HOURLY_COUNT}H $DATE_STRING)
DAILY_DELETE_TIME=$(date -v-${DAILY_COUNT}d $DATE_STRING)
WEEKLY_COUNT_IN_DAYS=$(($WEEKLY_COUNT*7))
WEEKLY_DELETE_TIME=$(date -v-${WEEKLY_COUNT_IN_DAYS}d $DATE_STRING)
MONTHLY_DELETE_TIME=$(date -v-${MONTHLY_COUNT}m $DATE_STRING)

# Loop through all of the files and delete the matching files
# declare -a files_to_delete
for backup in $DEST_PATH/* ; do
  if [ -f $backup ] ; then
    case "$backup" in
      "${DEST_PATH}/${ARCHIVE_NAME}_${HOURLY_DELETE_TIME}_HOURLY.tgz"* )
        files_to_delete=( "${files_to_delete[@]}" "$backup" )
        ;;
      "${DEST_PATH}/${ARCHIVE_NAME}_${DAILY_DELETE_TIME}_DAILY.tgz"* )
        files_to_delete=( "${files_to_delete[@]}" "$backup" )
        ;;
      "${DEST_PATH}/${ARCHIVE_NAME}_${WEEKLY_DELETE_TIME}_WEEKLY.tgz"* )
        files_to_delete=( "${files_to_delete[@]}" "$backup" )
        ;;
      "${DEST_PATH}/${ARCHIVE_NAME}_${MONTHLY_DELETE_TIME}_MONTHLY.tgz"* )
        files_to_delete=( "${files_to_delete[@]}" "$backup" )
        ;;
    esac
    #rm -rf $backup
  fi
done
for file_to_delete in "${files_to_delete[@]}" ; do
  echo "********** deleting this file **********"
  echo $file_to_delete
  if [ $? = 0 ] ; then
    echo "Old snapshot deleted"
  else
    # Write in some email code here.
    echo "Unable to delete the old snapshot. Exiting." ; exit $?
  fi
done
echo "********** number of files to delete **********"
echo ${#files_to_delete[@]}
#echo "${files_to_delete[@]}"
