#!/usr/bin/bash

date=$(date +"%y-%m-%d_%H:%M:%S")

tmp_folder="/appdata/tmp"
mkdir -p $tmp_folder

echo "------ ${date} ------" >> "${tmp_folder}/logs.txt"
echo "" >> "${tmp_folder}/logs.txt"

content='{"content": "**'$(date +"%y-%m-%d %H:%M:%S")'**", "embeds": ['
tmp=""


/root/git-repos/zeus-backup-scripts/video-cdn/script.sh
if [[ $? -ne 0 ]]; then
    echo "video-cdn/script.sh exited with a non zero exit code" >> "${tmp_folder}/logs.txt"
    tmp='{"title": "video-cdn", "color": 16711680}'
else
    echo "video-cdn/script.sh exited with a zero exit code" >> "${tmp_folder}/logs.txt"
    tmp='{"title": "video-cdn", "color": 65280}'
fi
content="${content}${tmp},"


/root/git-repos/zeus-backup-scripts/passbolt/script.sh
if [[ $? -ne 0 ]]; then
    echo "passbolt/script.sh exited with a non zero exit code" >> "${tmp_folder}/logs.txt"
    tmp='{"title": "passbolt", "color": 16711680}'
else
    echo "passbolt/script.sh exited with a zero exit code" >> "${tmp_folder}/logs.txt"
    tmp='{"title": "passbolt", "color": 65280}'
fi
content="${content}${tmp},"


/root/git-repos/zeus-backup-scripts/portainer/script.sh
if [[ $? -ne 0 ]]; then
    echo "portainer/script.sh exited with a non zero exit code" >> "${tmp_folder}/logs.txt"
    tmp='{"title": "portainer", "color": 16711680}'
else
    echo "portainer/script.sh exited with a zero exit code" >> "${tmp_folder}/logs.txt"
    tmp='{"title": "portainer", "color": 65280}'
fi
content="${content}${tmp},"


/root/git-repos/zeus-backup-scripts/grafana/script.sh
if [[ $? -ne 0 ]]; then
    echo "grafana/script.sh exited with a non zero exit code" >> "${tmp_folder}/logs.txt"
    tmp='{"title": "grafana", "color": 16711680}'
else
    echo "grafana/script.sh exited with a zero exit code" >> "${tmp_folder}/logs.txt"
    tmp='{"title": "grafana", "color": 65280}'
fi
content="${content}${tmp}"


echo "${content}]}" >> "${tmp_folder}/logs.txt"
echo "" >> "${tmp_folder}/logs.txt"
echo "" >> "${tmp_folder}/logs.txt"

/usr/bin/curl -i -H "Content-Type: application/json" -d  "${content}]}" "${DISCORD_WEBHOOK_URL}" >> "${tmp_folder}/logs.txt"