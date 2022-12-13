#!/usr/bin/bash

# backup name
name="passbolt"

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
b2 authorize-account $BACKB_KEY_ID $BACKB_APP_KEY 2>> "${tmp_folder}/logs/logs.txt"
if [[ $? -ne 0 ]]; then
    err=true
fi


# ------------------------------- BACKUP START


# backup db to .sql
docker exec -i passbolt-db-1 mysqldump -u passbolt --password="${PASSB_DB_PASSWORD}" passbolt > "${tmp_folder}/${date}/passbolt-sqlbkp_${date}.sql" 2>> "${tmp_folder}/logs/logs.txt"
if [[ $? -ne 0 ]]; then
    err=true
else
    # if ok then upload to Backblaze bucket
    b2 upload-file zeus-docker-backup "${tmp_folder}/${date}/passbolt-sqlbkp_${date}.sql" "${name}/${date}/passbolt-sqlbkp_${date}.sql" 2>> "${tmp_folder}/logs/logs.txt"
    if [[ $? -ne 0 ]]; then
        err=true
    fi
fi


# backup serverkey_private.asc
docker cp passbolt-app-1:/etc/passbolt/gpg/serverkey_private.asc "${tmp_folder}/${date}/passbolt-srvkey-privatebkp_${date}.asc"
if [[ $? -ne 0 ]]; then
    err=true
else
    # if ok then upload to Backblaze bucket
    b2 upload-file zeus-docker-backup "${tmp_folder}/${date}/passbolt-srvkey-privatebkp_${date}.asc" "${name}/${date}/passbolt-srvkey-privatebkp_${date}.asc" >> "${tmp_folder}/logs/logs.txt"
    if [[ $? -ne 0 ]]; then
        err=true
    fi
fi


# backup serverkey.asc
docker cp passbolt-app-1:/etc/passbolt/gpg/serverkey.asc "${tmp_folder}/${date}/passbolt-srvkeybkp_${date}.asc"
if [[ $? -ne 0 ]]; then
    err=true
else
    # if ok then upload to Backblaze bucket
    b2 upload-file zeus-docker-backup "${tmp_folder}/${date}/passbolt-srvkeybkp_${date}.asc" "${name}/${date}/passbolt-srvkeybkp_${date}.asc" 2>> "${tmp_folder}/logs/logs.txt"
    if [[ $? -ne 0 ]]; then
        err=true
    fi
fi


# backup nginx.conf
b2 upload-file zeus-docker-backup "/etc/nginx/conf.d/dev.komelt.passbolt.conf" "${name}/${date}/nginx-confbkp_${date}.conf" 2>> "${tmp_folder}/logs/logs.txt"
if [[ $? -ne 0 ]]; then
    err=true
fi


# backup docker-compose.yaml
# b2 upload-file zeus-docker-backup "/home/komelt/git-repos/boilerplates/passbolt/production.yaml" "${name}/${date}/docker-composebkp_${date}.yaml" 2>> "${tmp_folder}/logs/logs.txt"
# if [[ $? -ne 0 ]]; then
#     err=true
# fi


# backup serverkey.asc
docker cp passbolt-app-1:/usr/share/php/passbolt/plugins/Passbolt/WebInstaller/templates/Config/passbolt.php "${tmp_folder}/${date}/passbolt-confbkp_${date}.php"
if [[ $? -ne 0 ]]; then
    err=true
else
    # if ok then upload to Backblaze bucket
    b2 upload-file zeus-docker-backup "${tmp_folder}/${date}/passbolt-confbkp_${date}.php" "${name}/${date}/passbolt-confbkp_${date}.php" 2>> "${tmp_folder}/logs/logs.txt"
    if [[ $? -ne 0 ]]; then
        err=true
    fi
fi


# ------------------------------- BACKUP END


echo "" >> "${tmp_folder}/logs/logs.txt"
echo "" >> "${tmp_folder}/logs/logs.txt"

if [[ $err == "true" ]]; then
    exit 1
fi