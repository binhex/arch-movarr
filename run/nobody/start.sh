#!/usr/bin/dumb-init /bin/bash

# set install location for movarr
install_path="/opt/movarr"

# ensure we are in the install location
cd "${install_path}" || echo "Path does not exist '${install_path}'"

# create virtualenv
uv venv --quiet

# install dependencies from pyproject.toml into virtualenv and create uv.lock
uv sync --group dev

# activate vrtualenv
source './.venv/bin/activate'

# run movarr
movarr \
  --config-path "${MOVARR_CONFIG_PATH}" \
  --log-path "${MOVARR_LOG_PATH}" \
  --db-path "${MOVARR_DB_PATH}" \
  --pid-path "${MOVARR_PID_PATH}" \
  --log-level "${MOVARR_LOG_LEVEL}" \
  --library-path-list "${MOVARR_LIBRARY_PATH_LIST}" \
  --qbt-host "${MOVARR_QBT_HOST}" \
  --qbt-port "${MOVARR_QBT_PORT}" \
  --qbt-username "${MOVARR_QBT_USERNAME:-admin}" \
  --qbt-password "${MOVARR_QBT_PASSWORD:-adminadmin}" \
  --index-proxy "${MOVARR_INDEX_PROXY}" \
  --jackett-host "${MOVARR_JACKETT_HOST}" \
  --jackett-port "${MOVARR_JACKETT_PORT}" \
  --jackett-api-key "${MOVARR_JACKETT_API_KEY}" \
  --prowlarr-host "${MOVARR_PROWLARR_HOST}" \
  --prowlarr-port "${MOVARR_PROWLARR_PORT}" \
  --prowlarr-api-key "${MOVARR_PROWLARR_API_KEY}" \
  --daemon
