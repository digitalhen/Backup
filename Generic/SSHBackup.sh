#!/bin/sh

# check count
if [ $# -ne 3 ]
then
echo "$0 <source host> <source path> <target path>"
exit 2
fi

# settings
sourcehost=$1
backup=$2
target=$3

# check sourcehost is available
echo "Checking $sourcehost is available"
if [ `ssh -t $sourcehost whoami` ]
then
echo "$sourcehost is available, continuing."
else
echo "Can't connect to $sourcehost, so will quit."
exit 2
fi

# date for this backup
date=`date "+%Y-%m-%dT%H_%M_%S"`

# check and create lockfile
if [ -f ${target}lockfile ]
then
echo "Lockfile exists, backup stopped."
exit 2
else
touch ${target}lockfile
fi

# create folders if neccessary
if [ ! -e ${target}current ]
then
mkdir ${target}current
fi
if [ ! -d ${target}weekly ]
then
mkdir ${target}weekly
fi
if [ ! -d ${target}daily ]
then
mkdir ${target}daily
fi
if [ ! -d ${target}hourly ]
then
mkdir ${target}hourly
fi

# mark the backup time on the remote filesystem
ssh -t $sourcehost "date > $backup/lastbackup.txt"

# rsync
rsync \
-av \
--exclude "DoNotBackup" --exclude "BBC iPlayer" --exclude "Final Cut Events" --exclude "Final Cut Projects" --exclude "iMovie Events.localized" \
--delete \
--link-dest=${target}current \
-e ssh \
$sourcehost:$backup \
$target$date-incomplete

# backup complete, mark as read only and put in to tree
mv $target$date-incomplete ${target}hourly/$date
rm -r ${target}current
ln -s ${target}hourly/$date ${target}current
touch ${target}hourly/$date

# keep daily backup
if [ `find ${target}daily -maxdepth 1 -type d -mtime -2 -name "20*" | wc -l` -eq 0 ] && [ `find ${target}hourly -maxdepth 1 -name "20*" | wc -l` -gt 1 ]
then
oldest=`ls -1 -tr ${target}hourly/ | head -1`
mv ${target}hourly/$oldest ${target}daily/
fi

# keep weekly backup
if [ `find ${target}weekly -maxdepth 1 -type d -mtime -14 -name "20*" | wc -l` -eq 0 ] && [ `find ${target}daily -maxdepth 1 -name "20*" | wc -l` -gt 1 ]
then
oldest=`ls -1 -tr ${target}daily/ | head -1`
mv ${target}daily/$oldest ${target}weekly/
fi

# delete old backups, and 2 hour old incomplete backups
find ${target} -maxdepth 1 -name "*incomplete" -type d -mmin +120 | xargs rm -rvf 
find ${target}hourly -maxdepth 1 -type d -mtime +0 | xargs rm -rvf
find ${target}daily -maxdepth 1 -type d -mtime +7 | xargs rm -rvf

# remove lockfile
rm ${target}lockfile
