# Application

[movarr](https://github.com/binhex/movarr)

## Description

movarr is an automated movie torrent acquisition daemon written in Python.
It polls Jackett or Prowlarr for movie torrents, filters results against IMDb
metadata (rating, votes, year, runtime, language, genres, certification),
and adds matching torrents to qBittorrent. Once a torrent completes, movarr
can post-process it by copying the file to your media library with genre and
age-rating based routing rules.

## Build notes

Latest GitHub release.

## Usage

```bash
docker run -d \
    --name=<container name> \
    -v <path for config files>:/config \
    -v <path for media files>:/media \
    -v <path for data files>:/data \
    -v /etc/localtime:/etc/localtime:ro \
    -e MOVARR_LOG_LEVEL=INFO \
    -e MOVARR_QBT_HOST=<qbittorrent host> \
    -e MOVARR_QBT_PORT=<qbittorrent port> \
    -e MOVARR_QBT_USERNAME=<qbittorrent username> \
    -e MOVARR_QBT_PASSWORD=<qbittorrent password> \
    -e MOVARR_INDEX_PROXY=<jackett|prowlarr> \
    -e MOVARR_JACKETT_HOST=<jackett host> \
    -e MOVARR_JACKETT_PORT=<jackett port> \
    -e MOVARR_JACKETT_API_KEY=<jackett api key> \
    -e MOVARR_PROWLARR_HOST=<prowlarr host> \
    -e MOVARR_PROWLARR_PORT=<prowlarr port> \
    -e MOVARR_PROWLARR_API_KEY=<prowlarr api key> \
    -e ENABLE_STARTUP_SCRIPTS=yes|no \
    -e HEALTHCHECK_COMMAND=<command> \
    -e HEALTHCHECK_ACTION=<action> \
    -e HEALTHCHECK_HOSTNAME=<hostname> \
    -e UMASK=<umask for created files> \
    -e PUID=<uid for user> \
    -e PGID=<gid for user> \
    ghcr.io/binhex/arch-movarr
```

Please replace all user variables in the above command defined by <> with the
correct values.

## Example

```bash
docker run -d \
    --name=movarr \
    -v /apps/docker/movarr:/config \
    -v /media:/media \
    -v /apps/docker/qbittorrent/data/completed:/data:ro \
    -v /etc/localtime:/etc/localtime:ro \
    -e MOVARR_DAEMON=yes \
    -e MOVARR_LOG_LEVEL=INFO \
    -e MOVARR_QBT_HOST=binhex-qbittorrent \
    -e MOVARR_QBT_PORT=8080 \
    -e MOVARR_QBT_USERNAME=admin \
    -e MOVARR_QBT_PASSWORD=adminadmin \
    -e MOVARR_INDEX_PROXY=prowlarr \
    -e MOVARR_PROWLARR_HOST=binhex-prowlarr \
    -e MOVARR_PROWLARR_PORT=9696 \
    -e MOVARR_PROWLARR_API_KEY=your-api-key \
    -e ENABLE_STARTUP_SCRIPTS=yes \
    -e UMASK=000 \
    -e PUID=0 \
    -e PGID=0 \
    ghcr.io/binhex/arch-movarr
```

## Notes

User ID (PUID) and Group ID (PGID) can be found by issuing the following command
for the user you want to run the container as:-

```bash
id <username>
```

See the [movarr README](https://github.com/binhex/movarr) for full configuration
documentation and environment variable reference.

___
If you appreciate my work, then please consider buying me a beer  :D

[![PayPal donation](https://www.paypal.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=MM5E27UX6AUU4)

[Documentation](https://github.com/binhex/documentation) | [Support forum](https://forums.unraid.net/topic/198851-support-binhex-movarr/)
