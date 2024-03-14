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

# Function to remove files in the remote path that do not exist in the local path
sync_directories() {
    local_path=$1
    remote_path=$2
    host=$3
    user=$4
    port=$5
    password=$6

    # List files in local directory
    local_files=$(ls -1 "$local_path")

    # Generate a command to list files in the remote directory, compare with local files, and remove the difference
    remove_command=$(printf "ls -1 %s | grep -vFx -e %s | xargs -r rm -f" "$remote_path" "$local_files")

    # Execute the command on the remote server
    SSHPASS=$password sshpass -e ssh -o StrictHostKeyChecking=no -p $port $user@$host "$remove_command"
}

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

	# Call the function to sync directories
	sync_directories $5 $6 $2 $1 $3 ${10}

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
