#!/usr/bin/env sh
backup_path=path/tofolders
for backup in $backup_path/* ; do
    if [ -f $backup ] ; then
      # Get just filename
      filename=${backup##*/}
      echo $filename
      # Remove extension
      name=${filename%.*}
      echo $name
      # Get the filename backup type
      backup_type=${name##*_}
      echo $backup_type
      # Get the backup date
      backup_date=${name%_*}
      backup_date=${backup_date:(-13)}
      echo $backup_date
    fi
done
