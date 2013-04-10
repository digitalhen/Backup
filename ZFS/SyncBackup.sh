#!/bin/sh

# Check variable count
if [ $# -ne 2 ]
then
echo "$0 <source path> <target path>"
exit 2
fi

# Capture the variables
backup=$1
target=$2

# Check the file system is valid by checking for a last backup timestamp (this would need to be created manually the first time on the source)
echo "Checking data is available at $backup"
if [ -f ${backup}/lastbackup.txt ]
then
echo "lastbackup.txt found, continuing"
else
echo "Can't find lastbackup.txt in $backup, so will quit."
exit 2
fi

# Get the date for this backup
date=`date "+%Y-%m-%dT%H_%M_%S"`

# Stamp the backup on the source filesystem
date > ${backup}/lastbackup.txt

# Begin the Rsync. Various folders are excluded so as not to be included in any backups.
rsync \
-avP \
--exclude "\$RECYCLE.BIN" --exclude "DoNotBackup" --exclude "System Volume Information" --exclude "BBC iPlayer" --exclude "Final Cut Events" --exclude "Final Cut Projects" --exclude "iMovie Events.localized" \
--delete-after \
--delete-excluded \
$backup \
$target
