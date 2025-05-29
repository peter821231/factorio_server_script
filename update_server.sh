#!/bin/bash
# Setting
official_api="https://factorio.com/api/latest-releases"
official_dl_link="https://factorio.com/get-download/stable/headless/linux64"
local_dl_dir="/home/peter/factorio_dl"
local_server_home="/home/peter/factorio"
local_server_exe_path="${local_server_home}/bin/x64/factorio"

# Get server version from official server and local server
latest_version=$(curl -s ${official_api} | jq -r '.stable.headless')
current_version=$(${local_server_exe_path} --version | grep headless | awk '{print $2}')

function NO_UPDATE {
  echo "No update needed"
}

function UPDATE_SERVER {
  echo "Latest Version: ${latest_version}"
  echo "Current Version: ${current_version}"
  echo -n "Update server?(y/n): "
  read confirm
  if [[ $confirm == "y" || $confirm == "Y" ]]; then
    echo "Updating server..."
    # Download and update server automatically
    tmp_file="${local_dl_dir}/factorio-headless_linux_${latest_version}.tar.xz"
    wget -O "${tmp_file}" "${official_dl_link}"
    tar -xf "${tmp_file}" -C "${local_server_home}"
    echo "Update Complete"
  else
    echo "Cancel Update"
  fi
}

# Check server if need update
echo "Latest_version= ${latest_version}"
echo "Current_version= ${current_version}"

if [ "${current_version}" != "${latest_version}" ]; then
  UPDATE_SERVER
else
  NO_UPDATE
fi
