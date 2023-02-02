#!/usr/bin/bash

# backup name
name="video-cdn-ad4u"

next_base="/appdata/video-cdn/nextcloud/html"

date=$(date +"%y-%m-%d_%H:%M:%S")

# create necessary folders
tmp_folder="/appdata/tmp/${name}"
mkdir -p "${tmp_folder}/${date}"

# set-up logs
mkdir -p "${tmp_folder}/logs"
echo "------ ${date} ------" >> "${tmp_folder}/${date}/log_${date}.log"
echo "" >> "${tmp_folder}/${date}/log_${date}.log"

err=false

# ------------------------------- BACKUP START
docker exec --user www-data video-cdn-nextcloud-1 php occ maintenance:mode --on


# backup db to .sql
docker exec video-cdn-mariadb-1 mysqldump --single-transactio -u nextcloud --password="${NEXT_DB_PASS}" nextcloud > "${tmp_folder}/${date}/nextcloud-sqlbkp_${date}.sql" 2>> "${tmp_folder}/${date}/log_${date}.log" 
if [[ $? -ne 0 ]]; then
    err=true
fi


# backup nginx.conf
cp "/etc/nginx/conf.d/si.podjetni.video.conf" "${tmp_folder}/${date}/nginx-confbkp_${date}.conf" 2>> "${tmp_folder}/${date}/log_${date}.log"
if [[ $? -ne 0 ]]; then
    err=true
fi


# backup nextcloud folder
zip -r "${tmp_folder}/${date}/nextcloud-dirbkp_${date}.zip" "${next_base}" 2>> "${tmp_folder}/${date}/log_${date}.log"
if [[ $? -ne 0 ]]; then
    err=true
fi


docker exec --user www-data video-cdn-nextcloud-1 php occ maintenance:mode --off
# ------------------------------- BACKUP END

# ------------------------------- SYNC FILES START

# Remove directories that are older than 30 days
cd "${tmp_folder}"

find "${tmp_folder}"/* -mtime +30 -maxdepth 0 -exec basename {} \; | xargs rm -r {}

# Backblaze b2 authorize
b2 authorize-account $BACKB_KEY_ID $BACKB_APP_KEY 2>> "${tmp_folder}/${date}/log_${date}.log"
if [[ $? -ne 0 ]]; then
    err=true
fi

# Sync local cirectory with b2 bucket
b2 sync --delete --compareVersions none "${tmp_folder}" "b2://zeus-docker-backup/${name}/" 2>> "${tmp_folder}/${date}/log_${date}.log"
if [[ $? -ne 0 ]]; then
    err=true
fi

# ------------------------------- SYNC FILES END


echo "" >> "${tmp_folder}/${date}/log_${date}.log"
echo "" >> "${tmp_folder}/${date}/log_${date}.log"

if [[ $err == "true" ]]; then
    exit 1
fi