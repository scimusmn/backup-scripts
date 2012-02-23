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

ECHO="$(which echo)"
TAR="$(which tar)"
RSYNC="$(which rsync)"

# When should we make the daily backup - 24 hour time
DAILY_TIME=03
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

       REQUIRED
  -t   Backup destination path. Rsync and snapshot archives
       will be stored here.
  -n   A descriptive filename for the backup (no spaces)
       Example:
       apache_config
  -h   Number of hourly backups to retain.
  -d   Number of daily backups to retain.
  -w   Number of weekly backups to retain.
  -m   Number of monthly backups to retain.

       OPTIONAL
  -a   Alternate backup destination if primary path isn't
       available.
       This is provided for when the local path is a mounted
       drive that may or may not exist at the time the script
       is run.

EOF
}

# Get the command line arguments.
while getopts ":r:l:t:a:n:h:d:w:m:" opt ; do
  case $opt in
    r ) REMOTE_SOURCE=$OPTARG ;;
    l ) LOCAL_SOURCE_PATH=$OPTARG ;;
    t ) DEST_PATH=$OPTARG ;;

    a ) ALT_DEST_PATH=$OPTARG ;;

    n ) ARCHIVE_NAME=$OPTARG ;;
    h ) HOURLY_COUNT=$(($OPTARG)) ;;
    d ) DAILY_COUNT=$(($OPTARG)) ;;
    w ) WEEKLY_COUNT=$(($OPTARG)) ;;
    m ) MONTHLY_COUNT=$(($OPTARG)) ;;

    * ) $ECHO \n $usage
      exit 1 ;;
  esac
done

# Make sure the user has specified at least one backup source
if ( [ -z "$REMOTE_SOURCE" ] && [ -z "$LOCAL_SOURCE_PATH" ] ) ; then
  $ECHO ERROR: "You must specify either a remote or local source -r or -l"
  usage
  exit 1
fi

# Make sure the user hasn't specified two backup sources
if ( [ "$REMOTE_SOURCE" ] && [ "$LOCAL_SOURCE_PATH" ] ) ; then
  $ECHO ERROR: "You must specify either a remote or local source -r or -l. Not both."
  usage
  exit 1
fi

# Check for required arguments
if ( [ -z "$DEST_PATH" ] || [ -z $ARCHIVE_NAME ] || [ -z "$HOURLY_COUNT" ] || [ -z "$DAILY_COUNT" ] || [ -z "$WEEKLY_COUNT" ] || [ -z "$MONTHLY_COUNT" ] )
then
  $ECHO ERROR: "-t, -n, -h, -d, -w, -m are not optional.\n"
  usage
  exit 1
fi

############################################################
# Check for the destination folder
############################################################
# :TODO: Check for the remote destination as well
if [[ ! -d $DEST_PATH ]] ; then
  $ECHO "------------------------------------------------------------"
  $ECHO "The primary destination does not exist. Switching to alternate."
  $ECHO "------------------------------------------------------------"
  if [[ ! -d $ALT_DEST_PATH ]] ; then
    $ECHO "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    $ECHO ERROR: "The primary and alternate destinations are unavilable. Fatal error."
    $ECHO "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    usage
    exit 1
  else
    # Use the alternate destination for archiving.
    DEST_PATH=$ALT_DEST_PATH
  fi
else
  $ECHO "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  $ECHO "The primary desitnation exists. Using that."
  $ECHO "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
fi


############################################################
# rsync files with local backup
############################################################
$ECHO 'Syncing the backup with the server'

# rsync the files with these possible options
#   -a         (archive) Tells rsync to copy over, times, groups, symlinks, and
#              traverses directories
#   -v         (verbose)
#   -z         (compress) Use compression in the transfer
#   -P         (partial and progress) Save partially transfered files, and show
#              transfer progress
#   -e ssh     use SSH to do the transfer
#   --delete   delete files from the local backup that have been deleted from
#              the remote source
if [ "$REMOTE_SOURCE" ] ; then
  $RSYNC -avz -P -e ssh --delete $REMOTE_SOURCE $DEST_PATH
  # Get the name of the local folder where the rsync'ed files live
  # This is used when we archive this later.
  RSYNC_FOLDER=${REMOTE_SOURCE##*/}
elif [ "$LOCAL_SOURCE_PATH" ] ; then
  $RSYNC -avz -P $LOCAL_SOURCE_PATH $DEST_PATH
  RSYNC_FOLDER=${LOCAL_SOURCE_PATH##*/}
fi

############################################################
# Create grandfather, father, son snapshots
############################################################
$ECHO 'Creating a snapshot of the backup.'
# Current date
DOM=$(date +%d)

# Current day of the week
DOW=$(date +%u)

# The last day of this month
LAST_DOM=$($ECHO $(cal) | awk '{print $NF}')

# Current time, stored as a constant so we can use it at several points in the script
#DATE_STRING='+%Y_%m_%d_%H'
DATE_STRING='+%Y-%m-%dT%H:%M:%S%z'
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
$TAR czvf ${DEST_PATH}/${ARCHIVE_NAME}_${NOW}_${BAK_TYPE}.tgz $DEST_PATH/$RSYNC_FOLDER

############################################################
# Delete old snapshots
############################################################

# Create the matching date strings X , days, weeks, months back
HOURLY_DELETE_TIME=$(date -v-${HOURLY_COUNT}H $DATE_STRING)
DAILY_DELETE_TIME=$(date -v-${DAILY_COUNT}d $DATE_STRING)
WEEKLY_COUNT_IN_DAYS=$(($WEEKLY_COUNT*7))
WEEKLY_DELETE_TIME=$(date -v-${WEEKLY_COUNT_IN_DAYS}d $DATE_STRING)
MONTHLY_DELETE_TIME=$(date -v-${MONTHLY_COUNT}m $DATE_STRING)

# Loop through all of the files and populate an array of files to be deleted
declare -a files_to_delete
for backup in $DEST_PATH/* ; do
  if [ -f $backup ] ; then

    # Get just filename
    filename=${backup##*/}
    # Remove extension
    name=${filename%.*}
    # Get the filename snapshot type
    snapshot_type=${name##*_}
    # Get the snapshot date
    snapshot_date=${name%_*}
    snapshot_date=${snapshot_date:(-24)}

    snapshot_date=${snapshot_date#*_}
    # Convert the file date string to unix time
    snapshot_timestamp=`date_convert $snapshot_date`
    if [ $? -ne 0 ] ; then
      $ECHO "There was an error with the date_convert utility."
      exit 1
    fi


    case "$snapshot_type" in
      "HOURLY" )
        delete_timestamp=`date_convert $HOURLY_DELETE_TIME`
        ;;
      "DAILY" )
        delete_timestamp=`date_convert $DAILY_DELETE_TIME`
        ;;
      "WEEKLY" )
        delete_timestamp=`date_convert $WEEKLY_DELETE_TIME`
        ;;
      "MONTHLY" )
        delete_timestamp=`date_convert $MONTHLY_DELETE_TIME`
        ;;
    esac

    if [ $snapshot_timestamp -lt $delete_timestamp ] ; then
      files_to_delete=( "${files_to_delete[@]}" "$backup" )
    fi

  fi
done

# Delete files
for file_to_delete in "${files_to_delete[@]}" ; do
  rm -rf $file_to_delete
  if [ $? = 0 ] ; then
    $ECHO "Old snapshot deleted"
  else
    # Write in some email code here.
    $ECHO "Unable to delete the old snapshot. Exiting." ; exit $?
  fi
done
