#!/usr/bin/bash

# service name
name="passbolt"

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

# backup db to .sql
docker exec -i passbolt-db-1 mysqldump -u passbolt --password="${PASSBOLT_DB_PASSWORD}" passbolt > "${tmp_folder}/${date}/passbolt-sqlbkp.sql" 2>> "${tmp_folder}/logs/${date}.log"
if [[ $? -ne 0 ]]; then
    err=true
fi


# backup serverkey_private.asc
docker cp passbolt-app-1:/etc/passbolt/gpg/serverkey_private.asc "${tmp_folder}/${date}/passbolt-srvkey-privatebkp.asc" 2>> "${tmp_folder}/logs/${date}.log"
if [[ $? -ne 0 ]]; then
    err=true
fi


# backup serverkey.asc
docker cp passbolt-app-1:/etc/passbolt/gpg/serverkey.asc "${tmp_folder}/${date}/passbolt-srvkeybkp.asc" 2>> "${tmp_folder}/logs/${date}.log"
if [[ $? -ne 0 ]]; then
    err=true
fi


# backup nginx.conf
cp "/etc/nginx/conf.d/dev.komelt.passbolt.conf" "${tmp_folder}/${date}/nginx-confbkp.conf" 2>> "${tmp_folder}/logs/${date}.log" 
if [[ $? -ne 0 ]]; then
    err=true
fi


# backup serverkey.asc
docker cp passbolt-app-1:/usr/share/php/passbolt/plugins/PassboltCe/WebInstaller/templates/Config/passbolt.php "${tmp_folder}/${date}/passbolt-confbkp.php" 2>> "${tmp_folder}/logs/${date}.log"
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