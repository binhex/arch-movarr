#!/bin/bash

# exit script if return code != 0
set -e

# app name from buildx arg, used in healthcheck to identify app and monitor correct process
APPNAME="${1}"
shift

# release tag name from buildx arg, stripped of build ver using string manipulation
RELEASETAG="${1}"
shift

# target arch from buildx arg
TARGETARCH="${1}"
shift

if [[ -z "${APPNAME}" ]]; then
	echo "[warn] App name from build arg is empty, exiting script..."
	exit 1
fi

if [[ -z "${RELEASETAG}" ]]; then
	echo "[warn] Release tag name from build arg is empty, exiting script..."
	exit 1
fi

if [[ -z "${TARGETARCH}" ]]; then
	echo "[warn] Target architecture name from build arg is empty, exiting script..."
	exit 1
fi

# write APPNAME and RELEASETAG to file to record the app name and release tag used to build the image
echo -e "export APPNAME=${APPNAME}\nexport IMAGE_RELEASE_TAG=${RELEASETAG}\n" >> '/etc/image-build-info'

# ensure we have the latest builds scripts
refresh.sh

# pacman packages
####

# define pacman packages
pacman_packages="git python python-pip python-uv"

# install compiled packages using pacman
if [[ -n "${pacman_packages}" ]]; then
	# arm64 currently targetting aor not archive, so we need to update the system first
	if [[ "${TARGETARCH}" == "arm64" ]]; then
		pacman -Syu --noconfirm
	fi
	pacman -S --needed $pacman_packages --noconfirm
fi

# github
####

install_path="/opt/movarr"

mkdir -p "${install_path}"
github.sh --install-path "${install_path}" --github-owner 'binhex' --github-repo 'movarr' --query-type 'release' --download-branch 'main'

# container perms
####

# define comma separated list of paths
install_paths="/opt/movarr,/home/nobody"

# split comma separated string into list for install paths
IFS=',' read -ra install_paths_list <<< "${install_paths}"

# process install paths in the list
for i in "${install_paths_list[@]}"; do

	# confirm path(s) exist, if not then exit
	if [[ ! -d "${i}" ]]; then
		echo "[crit] Path '${i}' does not exist, exiting build process..." ; exit 1
	fi

done

# convert comma separated string of install paths to space separated, required for chmod/chown processing
install_paths=$(echo "${install_paths}" | tr ',' ' ')

# set permissions for container during build - Do NOT double quote variable for install_paths otherwise this will wrap space separated paths as a single string
chmod -R 775 ${install_paths}

# In install.sh heredoc, replace the chown section:
cat <<EOF > /tmp/permissions_heredoc
install_paths="${install_paths}"
EOF

# replace permissions placeholder string with contents of file (here doc)
sed -i '/# PERMISSIONS_PLACEHOLDER/{
    s/# PERMISSIONS_PLACEHOLDER//g
    r /tmp/permissions_heredoc
}' /usr/bin/init.sh
rm /tmp/permissions_heredoc

# env vars
####

cat <<'EOF' > /tmp/envvars_heredoc

# source in utility functions, need process_env_var
source utils.sh

# Define environment variables to process
# Format: "VAR_NAME:DEFAULT_VALUE:REQUIRED:MASK"
env_vars=(
	"MOVARR_DAEMON::true:false"
	"MOVARR_LOG_LEVEL:INFO:false:false"
	"MOVARR_LIBRARY_PATH_LIST::false:false"
	"MOVARR_QBT_HOST::true:false"
	"MOVARR_QBT_PORT::true:false"
	"MOVARR_QBT_USERNAME::true:false"
	"MOVARR_QBT_PASSWORD::true:true"
	"MOVARR_INDEX_PROXY::true:false"
	"MOVARR_JACKETT_HOST::false:false"
	"MOVARR_JACKETT_PORT::false:false"
	"MOVARR_JACKETT_API_KEY::false:true"
	"MOVARR_PROWLARR_HOST::false:false"
	"MOVARR_PROWLARR_PORT::false:false"
	"MOVARR_PROWLARR_API_KEY::false:true"
	"MOVARR_CONFIG_PATH::false:false"
	"MOVARR_DB_PATH::false:false"
	"MOVARR_LOG_PATH::false:false"
	"MOVARR_PID_PATH::false:false"
	"ENABLE_STARTUP_SCRIPTS:no:false:false"
)

# Process each environment variable
for env_var in "${env_vars[@]}"; do
	IFS=':' read -r var_name default_value required mask_value <<< "${env_var}"
	process_env_var "${var_name}" "${default_value}" "${required}" "${mask_value}"
done
EOF

# replace env vars placeholder string with contents of file (here doc)
sed -i '/# ENVVARS_PLACEHOLDER/{
    s/# ENVVARS_PLACEHOLDER//g
    r /tmp/envvars_heredoc
}' /usr/bin/init.sh
rm /tmp/envvars_heredoc

# config
####

cat <<'EOF' > /tmp/config_heredoc

if [[ "${ENABLE_STARTUP_SCRIPTS}" == "yes" ]]; then

	# define path to scripts
	base_path="/config/movarr"
	user_script_path="${base_path}/scripts"

	mkdir -p "${user_script_path}"

	# copy example startup script
	# note slence stdout/stderr and ensure exit code 0 due to src file may not exist (symlink)
	if [[ ! -f "${user_script_path}/example-startup-script.sh" ]]; then
		cp "/home/nobody/scripts/example-startup-script.sh" "${user_script_path}/example-startup-script.sh" 2> /dev/null || true
	fi

	# find any scripts located in "${user_script_path}"
	user_scripts=$(find "${user_script_path}" -maxdepth 1 -name '*sh' 2> '/dev/null' | xargs)

	# loop over scripts, make executable and source
	for i in ${user_scripts}; do
		chmod +x "${i}"
		echo "[info] Executing user script '${i}' in the background" | ts '%Y-%m-%d %H:%M:%.S'
		source "${i}" &
	done

	# change ownership as we are running as root
	chown -R nobody:users "${base_path}"

fi
EOF

# replace config placeholder string with contents of file (here doc)
sed -i '/# CONFIG_PLACEHOLDER/{
    s/# CONFIG_PLACEHOLDER//g
    r /tmp/config_heredoc
}' /usr/bin/init.sh
rm /tmp/config_heredoc

# cleanup
cleanup.sh
