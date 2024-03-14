#!/bin/sh -l

#set -e at the top of your script will make the script exit with an error whenever an error occurs (and is not explicitly handled)
set -eu

TEMP_SSH_PRIVATE_KEY_FILE='../private_key.pem'
TEMP_SFTP_FILE='../sftp'

# make sure remote path is not empty
if [ -z "$6" ]; then
   echo 'remote_path is empty'
   exit 1
fi

# use password
if [ -z != ${10} ]; then
	echo 'use sshpass'
	apk add sshpass

	if test $9 == "true";then
  		echo 'Start delete remote files'
		sshpass -p ${10} ssh -o StrictHostKeyChecking=no -p $3 $1@$2 rm -rf $6
	fi
	if test $7 = "true"; then
  		echo "Connection via sftp protocol only, skip the command to create a directory"
	else
 	 	echo 'Create directory if needed'
 	 	sshpass -p ${10} ssh -o StrictHostKeyChecking=no -p $3 $1@$2 mkdir -p $6
	fi

	echo 'SFTP Start'
	# create a temporary file containing sftp commands
	printf "%s" "put -r $5 $6" >$TEMP_SFTP_FILE
	#-o StrictHostKeyChecking=no avoid Host key verification failed.
	SSHPASS=${10} sshpass -e sftp -oBatchMode=no -b $TEMP_SFTP_FILE -P $3 $8 -o StrictHostKeyChecking=no $1@$2

	echo 'Checking for files to remove from remote...'
	# Generate a local file list
	local_files=$(find "$5" -type f | sed "s|^$5/||" | sort)
	echo "$local_files" > /tmp/local_files.txt
	
	# Generate a remote file list
	remote_files=$(sshpass -p "${10}" ssh -o StrictHostKeyChecking=no -p "$3" "$1@$2" "find $6 -type f | sed 's|^$6/||'" | sort)
	echo "$remote_files" > /tmp/remote_files.txt
	
	# Identify files to remove
	files_to_remove=$(comm -23 /tmp/remote_files.txt /tmp/local_files.txt)
	
	# Remove the identified files from the remote path
	if [ ! -z "$files_to_remove" ]; then
	    echo "Removing files from remote that don't exist locally..."
	    echo "$files_to_remove" | while IFS= read -r file; do
	        sshpass -p "${10}" ssh -o StrictHostKeyChecking=no -p "$3" "$1@$2" "rm -f '$6/$file'"
	    done
	else
	    echo "No files to remove. Remote directory is synced with local."
	fi
	
	# Clean up temporary files
	rm /tmp/local_files.txt /tmp/remote_files.txt

	echo 'Deploy Success'

    exit 0
fi

# keep string format
printf "%s" "$4" >$TEMP_SSH_PRIVATE_KEY_FILE
# avoid Permissions too open
chmod 600 $TEMP_SSH_PRIVATE_KEY_FILE

# delete remote files if needed
if test $9 == "true";then
  echo 'Start delete remote files'
  ssh -o StrictHostKeyChecking=no -p $3 -i $TEMP_SSH_PRIVATE_KEY_FILE $1@$2 rm -rf $6
fi

if test $7 = "true"; then
  echo "Connection via sftp protocol only, skip the command to create a directory"
else
  echo 'Create directory if needed'
  ssh -o StrictHostKeyChecking=no -p $3 -i $TEMP_SSH_PRIVATE_KEY_FILE $1@$2 mkdir -p $6
fi

echo 'SFTP Start'
# create a temporary file containing sftp commands
printf "%s" "put -r $5 $6" >$TEMP_SFTP_FILE
#-o StrictHostKeyChecking=no avoid Host key verification failed.
sftp -b $TEMP_SFTP_FILE -P $3 $8 -o StrictHostKeyChecking=no -i $TEMP_SSH_PRIVATE_KEY_FILE $1@$2

echo 'Deploy Success'
exit 0
