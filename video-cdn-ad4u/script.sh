#!/usr/bin/bash

# backup name
name="video-cdn-ad4u"

date=$(date +"%y-%m-%d_%H:%M:%S")

# create necessary folders
tmp_folder="/appdata/tmp/${name}"
mkdir -p "${tmp_folder}/${date}"

# set-up logs
mkdir -p "${tmp_folder}/logs"
echo "------ ${date} ------" >> "${tmp_folder}/logs/logs.txt"
echo "" >> "${tmp_folder}/logs/logs.txt"

err=false

# Backblaze b2 authorize
b2 authorize-account $BACKB_KEY_ID $BACKB_APP_KEY >> "${tmp_folder}/logs/logs.txt"
if [[ $? -ne 0 ]]; then
    err=true
fi

# backup db to .sql
docker exec cloud-komelt-dev_nextcloud-db-1 /usr/bin/mysqldump -u nextcloud --password="${NEXT_DB_PASS}" nextcloud > "${tmp_folder}/${date}/db_${date}.sql" 2>> "${tmp_folder}/logs/logs.txt" 
if [[ $? -ne 0 ]]; then
    err=true
else
    # if ok then upload to Backblaze bucket
    b2 upload-file zeus-docker-backup "${tmp_folder}/${date}/db_${date}.sql" "${name}/${date}/db/db_${date}.sql" >> "${tmp_folder}/logs/logs.txt"
    if [[ $? -ne 0 ]]; then
        err=true
    fi
fi

b2 upload-file zeus-docker-backup "/etc/nginx/conf.d/si.podjetni.video.conf" "${name}/${date}/nginx/nginx_si.podjetni.video_${date}.conf" >> "${tmp_folder}/logs/logs.txt"
if [[ $? -ne 0 ]]; then
    err=true
fi

echo "" >> "${tmp_folder}/logs/logs.txt"
echo "" >> "${tmp_folder}/logs/logs.txt"

if [[ $err == "true" ]]; then
    exit 1
fi