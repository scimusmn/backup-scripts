#!/usr/bin/env sh

############################################################
# backup_mysql.sh
#
# A script to backup all mysql tables on a given server into
# seperate .sql.gz files
#
# Inspiration from:
# http://bash.cyberciti.biz/backup/backup-mysql-database-server-2/
############################################################

GZIP="$(which gzip)"
ECHO="$(which echo)"
CHOWN="$(which chown)"
CHMOD="$(which chmod)"

BACKUP_DEST=''

# Usage description
usage ()
{
cat << EOF
USAGE: $0 arguments

This script makes mysql backups of all tables

ARGUMENTS:
   ?   Display this help.

       SELECT AN OPERATION MODE
       Select one of these arguments to define how the
       script will operate.
  -a   Archive mode
       mysqldumps are archived as timestamped, gunziped files. This
       script will not overwrite old versions of the backups.
  -r   rsync mode ***BEWARE***
       In this mode, the script ***will erase everything*** in your
       destination folder and then save gunziped dumps of each of
       your databases. This mode is designed so that you can rsync
       this folder off to another server to get a current snapshot
       of your database.

       REQUIRED ARGUMENTS
  -u   Username
  -p   Password
  -h   Hostname
  -d   Destination

EOF
}

# Get the command line arguments.
while getopts ":aru:p:h:d:" opt ; do
  case $opt in
    a ) ARCHIVE_METHOD=TRUE ;;
    r ) RSYNC_METHOD=TRUE ;;
    u ) MYSQLUSER=$OPTARG ;;
    p ) MYSQLPASS=$OPTARG ;;
    h ) MYSQLHOST=$OPTARG ;;
    d ) MYSQL_BACKUP_DEST=$OPTARG ;;

    * ) echo \n $usage
      exit 1 ;;
  esac
done

# Make sure the user has specified at least one backup mode
if ( [ -z "$ARCHIVE_METHOD" ] && [ -z "$RSYNC_METHOD" ] ) ; then
  echo ERROR: "You must specify a backup mode. Either -a archive or -r rsync method."
  usage
  exit 1
fi

# Make sure the user hasn't specified two backup sources
if ( [ "$ARCHIVE_METHOD" ] && [ "$RSYNC_METHOD" ] ) ; then
  echo ERROR: "Only supply one backup mode. Either -a archive or -r rsync method. Not both."
  usage
  exit 1
fi

# Make sure the user has specified all the required attributes
if ( [ -z "$MYSQLUSER" ] || [ -z "$MYSQLPASS" ] || [ -z "$MYSQLHOST" ] || [ -z "$MYSQL_BACKUP_DEST" ] ) ; then
  echo ERROR: "You must specify a mysql username, password, and host."
  usage
  exit 1
fi
# ------------------------------------------------
#
# Backup MYSQL databases
#
# ------------------------------------------------

# Linux bin paths, change this if it can't be autodetected via which command
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"

# Get data in dd-mm-yyyy format
NOW="$(date "+%Y_%m_%d_%H_%M")"

# File to store current backup file
FILE=""
# Store list of databases
DBS=""

# DO NOT BACKUP these databases
# TODO Make this an argument in the future
IGNORE="test"

[ ! -d $MYSQL_BACKUP_DEST ] && mkdir -p $MYSQL_BACKUP_DEST || :

# If you are using the rsync method, delete any existing files
# in the backup destination.
if [ $RSYNC_METHOD ]; then
  find $MYSQL_BACKUP_DEST -type f -exec rm {} \;
fi

# Get a list of all the databases
# -B (force each table onto a new line),
# -s (omit the table formatting),
# -e (execute a mysql command)
DBS="$($MYSQL -u $MYSQLUSER -p$MYSQLPASS -h $MYSQLHOST -Bse 'show databases')"

echo "here"
# mysqldump each database individualy
for db in $DBS
do
  skipdb=-1
  if [ "$IGNORE" != "" ]; then
    for i in $IGNORE
    do
      [ "$db" = "$i" ] && skipdb=1 || :
    done
  fi

  if [ "$skipdb" = "-1" ] ; then
    # Don't write the date into the filename for the rsync mode
    if [ $ARCHIVE_METHOD ]; then
      FILE="$MYSQL_BACKUP_DEST/$db.$MYSQLHOST.$NOW.gz"
    elif [ $RSYNC_METHOD ]; then
      FILE="$MYSQL_BACKUP_DEST/$db.$MYSQLHOST.gz"
    fi

    if ( [ "$db" = "information_schema" ] || [ "$db" = "performance_schema" ] ); then
      # Add this skip lock tables flag for backing up the
      # schema tables. This is required by MySQL after 5.1.38
      MYSQLDUMPARGS="--skip-lock-tables "
    fi

    # mysqldump and pipe it to gzip
    $MYSQLDUMP -u $MYSQLUSER -h $MYSQLHOST -p$MYSQLPASS $MYSQLDUMPARGS$db | $GZIP -9 > $FILE
    $ECHO "Table backed up : $db"
  fi
done
