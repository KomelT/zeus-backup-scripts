#!/usr/bin/bash

date=$(date +"%y-%m-%d_%H:%M:%S")

tmp_folder="/appdata/tmp"
mkdir -p $tmp_folder

echo "------ ${date} ------" >> "${tmp_folder}/logs.txt"
echo "" >> "${tmp_folder}/logs.txt"

content='{"content": "**'$(date +"%y-%m-%d %H:%M:%S")'**", "embeds": ['
tmp=""


/root/zeus-docker-backup-scripts/video-cdn-ad4u/script.sh
if [[ $? -ne 0 ]]; then
    echo "video-cdn-ad4u/script.sh exited with a non zero exit code" >> "${tmp_folder}/logs.txt"
    tmp='{"title": "video-cdn-ad4u", "description": "NOK! Please check logs.", "color": 16711680}'
else
    echo "video-cdn-ad4u/script.sh exited with a zero exit code" >> "${tmp_folder}/logs.txt"
    tmp='{"title": "video-cdn-ad4u", "description": "OK!", "color": 65280}'
fi
content="${content}${tmp},"


/root/zeus-docker-backup-scripts/passbolt/script.sh
if [[ $? -ne 0 ]]; then
    echo "passbolt/script.sh exited with a non zero exit code" >> "${tmp_folder}/logs.txt"
    tmp='{"title": "passbolt", "description": "NOK! Please check logs.", "color": 16711680}'
else
    echo "passbolt/script.sh exited with a zero exit code" >> "${tmp_folder}/logs.txt"
    tmp='{"title": "passbolt", "description": "OK!", "color": 65280}'
fi
content="${content}${tmp}"


echo "${content}]}" >> "${tmp_folder}/logs.txt"

/usr/bin/curl -i -H "Content-Type: application/json" -d  "${content}]}" "${DISC_WEBHOOK_URL}" >> "${tmp_folder}/logs.txt"