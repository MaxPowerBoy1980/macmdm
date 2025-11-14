#!/bin/bash

# Enable Company Portal SSO + autofill extensions for the console user.
# Designed to run as root so launchctl/pluginkit can reach the UI session.
# Version history:
#  1.0.0 – Initial helper (Microsoft sample)
#  1.0.1 – Added console-user lookup rather than $USER.
#  1.0.2 – Added logging and version banner.
script_version="1.0.2"

log() {
    echo "$(date) | $1"
}

# Determine actual console user (needed when script runs via sudo)
current_user=$(stat -f%Su /dev/console)
uid=$(id -u "$current_user")
log "Starting enable_CP_extensions.sh version $script_version for $current_user (uid $uid)"

# List of extension bundle IDs
extensions=(
    "com.microsoft.CompanyPortalMac.ssoextension"
    "com.microsoft.CompanyPortalMac.Mac-Autofill-Extension"
)

for extension in "${extensions[@]}"; do
    log "Checking for extension: $extension"

    # Check if extension exists
    if launchctl asuser "$uid" bash -c "pluginkit -m | grep \"$extension\"" > /dev/null; then
        log "Extension found: $extension"
    else
        log "Error: Extension not found: $extension"
        log "Skipping..."
        continue
    fi

    # Check if the extension is enabled
    if launchctl asuser "$uid" bash -c "pluginkit -m | grep \"+    $extension\"" > /dev/null; then
        log "$extension is already enabled"
    else
        log "$extension is not enabled. Enabling now..."
        launchctl asuser "$uid" bash -c "pluginkit -e use -i \"$extension\""
        log "$extension has been enabled"
    fi
done
