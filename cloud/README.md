# Cloud Storage

Shared /mnt/media/cloud root.

## Layout

/mnt/media/cloud/{nextcloud/,syncthing/,immich/,shared/}

## Usage

Mount in compose: - /mnt/media/cloud/nextcloud:/var/www/html

chown -R 1000:1000 /mnt/media/cloud

No compose here—docs only.