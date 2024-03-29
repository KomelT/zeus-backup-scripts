#!/usr/bin/bash

# service name
name="video-cdn"

nextcloud_location="/appdata/video-cdn/nextcloud"

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

docker exec --user www-data video-cdn-nextcloud-1 php occ maintenance:mode --on 2>> "${tmp_folder}/logs/${date}.log"
if [[ $? -ne 0 ]]; then
    err=true
fi

# backup db to .sql
docker exec video-cdn-mariadb-1 mysqldump --single-transaction -u nextcloud --password="${NEXTCLOUD_DB_PASSWORD}" nextcloud > "${tmp_folder}/${date}/nextcloud-sqlbkp.sql" 2>> "${tmp_folder}/logs/${date}.log" 
if [[ $? -ne 0 ]]; then
    err=true
fi


# backup nginx.conf
mkdir "${tmp_folder}/${date}/nginx/"
cd /etc/nginx/conf.d/

find . -name "video-cdn_*" -exec cp {} "${tmp_folder}/${date}/nginx/" \; 2>> "${tmp_folder}/logs/${date}.log"
if [[ $? -ne 0 ]]; then
    err=true
fi


# backup nextcloud folder
zip -r "${tmp_folder}/${date}/nextcloud-dirbkp.zip" "${nextcloud_location}/html" 2>> "${tmp_folder}/logs/${date}.log"
if [[ $? -ne 0 ]]; then
    err=true
fi


docker exec --user www-data video-cdn-nextcloud-1 php occ maintenance:mode --off 2>> "${tmp_folder}/logs/${date}.log"
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



# ------------------------------- SYNC BIG FILES START

day=$(date +%u)

if [ "$day" == "7" ]; then
    ssh -i "${HOME}/.ssh/id_rsa" root@192.168.1.18 mkdir -p "/data/${name}/data/weekly/" 2>> "${tmp_folder}/logs/${date}.log"
    if [[ $? -ne 0 ]]; then
        err=true
    fi

    rsync -au "${nextcloud_location}/data" -e "ssh -i ${HOME}/.ssh/id_rsa" root@192.168.1.18:"/data/${name}/data/weekly/" --delete 2>> "${tmp_folder}/logs/${date}.log"
    if [[ $? -ne 0 ]]; then
        err=true
    fi
else
    ssh -i "${HOME}/.ssh/id_rsa" root@192.168.1.18 mkdir -p "/data/${name}/data/daily/" 2>> "${tmp_folder}/logs/${date}.log"
    if [[ $? -ne 0 ]]; then
        err=true
    fi

    rsync -au "${nextcloud_location}/data" -e "ssh -i ${HOME}/.ssh/id_rsa" root@192.168.1.18:"/data/${name}/data/daily/" --delete 2>> "${tmp_folder}/logs/${date}.log"
    if [[ $? -ne 0 ]]; then
        err=true
    fi
fi

# ------------------------------- SYNC BIG FILES END



echo "" >> "${tmp_folder}/logs/${date}.log"
echo "" >> "${tmp_folder}/logs/${date}.log"

if [[ $err == "true" ]]; then
    exit 1
fi