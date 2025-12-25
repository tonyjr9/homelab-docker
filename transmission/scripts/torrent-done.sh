#!/bin/bash
# Transmission torrent completion script
# Runs when a torrent finishes downloading

# Get the completed file path
TORRENT_PATH="$TR_TORRENT_DIR/$TR_TORRENT_NAME"

# Determine if it's a movie or TV show based on folder name
if [[ "$TR_TORRENT_DIR" == *"radarr"* ]]; then
    # It's a movie - notify Radarr
    echo "[$(date)] Movie completed: $TR_TORRENT_NAME - Notifying Radarr..." >> /tmp/transmission-notify.log
    
    # Call Radarr API to scan for new movies
    curl -s -X POST "http://radarr:7878/api/v3/command" \
        -H "Content-Type: application/json" \
        -H "X-Api-Key: 786bf646ad314f1196f62aa9c717e3e9" \
        -d '{"name":"DownloadedMoviesScan"}' >> /tmp/transmission-notify.log 2>&1
        
elif [[ "$TR_TORRENT_DIR" == *"sonarr"* ]] || [[ "$TORRENT_PATH" == *"tv"* ]]; then
    # It's a TV show - notify Sonarr
    echo "[$(date)] TV show completed: $TR_TORRENT_NAME - Notifying Sonarr..." >> /tmp/transmission-notify.log
    
    # Call Sonarr API to scan for new episodes
    curl -s -X POST "http://sonarr:8989/api/v3/command" \
        -H "Content-Type: application/json" \
        -H "X-Api-Key: 5e2e6dfb39cf481fb53a7b9a15f125eb" \
        -d '{"name":"DownloadedEpisodesScan"}' >> /tmp/transmission-notify.log 2>&1
else
    # Unknown - try both
    echo "[$(date)] Unknown type, notifying both: $TR_TORRENT_NAME..." >> /tmp/transmission-notify.log
    
    curl -s -X POST "http://radarr:7878/api/v3/command" \
        -H "Content-Type: application/json" \
        -H "X-Api-Key: 786bf646ad314f1196f62aa9c717e3e9" \
        -d '{"name":"DownloadedMoviesScan"}' >> /tmp/transmission-notify.log 2>&1
    
    curl -s -X POST "http://sonarr:8989/api/v3/command" \
        -H "Content-Type: application/json" \
        -H "X-Api-Key: 5e2e6dfb39cf481fb53a7b9a15f125eb" \
        -d '{"name":"DownloadedEpisodesScan"}' >> /tmp/transmission-notify.log 2>&1
fi

exit 0

