#!/usr/bin/bash

# service name
name="portainer"

portainer_location="/var/lib/docker/volumes/portainer_data/_data"

date=$(date +"%y-%m-%d_%H:%M:%S")

# create necessary folders
tmp_folder="/appdata/tmp/${name}"
mkdir -p "${tmp_folder}/${date}"

# set-up logs
mkdir -p "${tmp_folder}/logs"
echo "------ ${date} ------" >> "${tmp_folder}/logs/${date}.log"
echo "" >> "${tmp_folder}/logs/${date}.log"

err=false



# ------------------------------- BACKUP START

zip "${tmp_folder}/${date}/portainer-bkp.zip" "${portainer_location}" 2>> "${tmp_folder}/logs/${date}.log"
if [[ $? -ne 0 ]]; then
    err=true
fi

# ------------------------------- BACKUP END



# ------------------------------- SYNC FILES START

# Remove directories that are older than 30 days
cd "${tmp_folder}"

find "${tmp_folder}"/* -mtime +30 -maxdepth 0 -exec basename {} \; | xargs rm -r {}

ssh -i "${HOME}/.ssh/id_rsa" root@192.168.1.18 mkdir -p "/data/${name}/config/" 2>> "${tmp_folder}/logs/${date}.log"
if [[ $? -ne 0 ]]; then
    err=true
fi

rsync -au "/appdata/tmp/${name}/" -e "ssh -i ${HOME}/.ssh/id_rsa" root@192.168.1.18:"/data/${name}/config/" --delete 2>> "${tmp_folder}/logs/${date}.log"
if [[ $? -ne 0 ]]; then
    err=true
fi

# ------------------------------- SYNC FILES END



echo "" >> "${tmp_folder}/logs/${date}.log"
echo "" >> "${tmp_folder}/logs/${date}.log"

if [[ $err == "true" ]]; then
    exit 1
fi