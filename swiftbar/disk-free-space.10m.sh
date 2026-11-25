#!/bin/bash

volumes=(Vault VaultBackup OfflineVault)

for volume in ${volumes[@]}; do
    printf -v $volume '%s' "$(df -h /Volumes/$volume 2>/dev/null | grep /Volumes/$volume\$ | awk '{print $5}')"
    if [ -z "${!volume}" ]; then
        printf -v $volume '%s' "⏏"
    fi
done

echo -n "⛁ "
for volume in ${volumes[@]}; do
    printf '%s%s' "$sep" "${!volume}"
    sep=/
done
echo
echo "---"
for volume in ${volumes[@]}; do
    echo "$volume: ${!volume}"
done
