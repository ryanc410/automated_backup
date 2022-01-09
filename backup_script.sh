#!/usr/bin/env bash

pull_script=/usr/local/bin/pull_backup.sh
backup_script=/usr/local/bin/backup.sh

function title()
{
    clear
    echo "#---------------------------------#"
    echo "#     AUTOMATED BACKUP SCRIPT     #"
    echo "#---------------------------------#"
    echo 
}

title
echo "The Automated Backup Script needs to gather some information."
title
echo "Enter the IP Address of the Remote Server you want to run regular backups on:"
read ip_address
ping -c 1 "$ip_address" &>/dev/null
while [ $? != 0 ];
do
    echo "$ip_address could not be contacted on the network."
    sleep 3
    echo "Check the address and try again."
    sleep 3
    title
    echo "Enter the IP Address of the Remote Server you want to run regular backups on:"
    read ip_address
done
echo "Enter the Remote Servers SSH Listen Port:"
read ssh_port
echo "Enter the path to the private key file used to authenticate with the remote server:"
read private_key
while [ ! -f $private_key ];
do
    echo "The private key at $private_key could not be found."
    sleep 3
    echo "Check the path and try again."
    sleep 3
    echo "Enter the path to the private key file used to authenticate with the remote server:"
    read private_key
done
title
echo "The script has gathered all the information it needs."
sleep 3
echo "Beginning Installation now."
sleep 2
ssh -P "$ssh_port" -i "$private_key" "$user"@"$ip_address"<<COMMANDS
cat >> "$backup_script" <<-_EOF_
!/usr/bin/env bash

# If you only want to Backup part of your server you can change the variable below. Check documentation for specific instructions.
backup_files=/

# Nothing below this line should be changed
day=$(date +%B.%d.%Y)
backup_dest=/home/backups/
host=$(hostname -s)
filename="$day"."$host".tar.bz2

if [[ ! -d $backup_dest ]]; then
    mkdir -p "$backup_dest"
fi

if [[ ! -z $backup_dest ]]; then
    rm -rf "$backup_dest/*"
fi

tar cfj "$filename" "${backup_files[$*]}" &>/dev/null
mv "$filename" "$backup_dest" &>/dev/null
_EOF_
COMMANDS

cat >> "$pull_script" <<-_FILE_
#!/usr/bin/env bash

# IP Address of remote server
ip="$ip_address"
# DO NOT CHANGE 
user=root
# SSH Listen port of remote server
port="$ssh_port"
# The path to the private key that matches the authorized_keys file on remote server
keyfile="$private_key"
backup_dir=/home/backups/

sftp -i "$keyfile" -P "$port" "$user"@"$ip" &>/dev/null<< _EOF_
get "$backup_dir"* &>/dev/null
rm "$backup_dir"* &>/dev/null
bye &>/dev/null
_EOF_
_FILE_

chmod +x "$pull_script"
