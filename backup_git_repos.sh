#!/usr/bin/env sh

############################################################
# backup_git_repos.sh
#
# Backup all of the bare git repos in a central directory.
# - Make a bare clone of each git repo
# - Compress it
# - Move it to the a folder for remote rsync'ing
############################################################

repos=()
backup_datetime=$(date +%Y_%m_%d_T%H_%M_%S)
for repo in ${repos[@]}
do
  dest_dir=""
  dest_file=$repo"_git_"$backup_datetime
  dest=$dest_dir$dest_file
  echo "==============================="
  echo -e "CLONING "$repo"\r"
  git clone --bare git@servername.domain$repo.git $dest
  echo "==============================="
  echo -e "COMPRESSING "$repo"\r"
  tar vczf $dest.tgz -C $dest_dir $dest_file
  rm -rf $dest
  echo "==============================="
  echo "SAVING to destination"
  cp $dest.tgz /some/place
  rm $dest.tgz
done

