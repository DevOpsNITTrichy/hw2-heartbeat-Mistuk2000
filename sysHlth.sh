#!/bin/bash

log_file="/var/log/syslog" # Replace with the actual log file path

# Initialize variables
wifi_connection_count=0
ntp_timeout_count=0
fingerprint_error=0
apparmor_denied_count=0
kerneloops_error=0
network_manager_state_changes=()
network_manager_states=()
services_started=()
services_failed=()
services_deactivated=()
device_errors=()

# Process the log file line by line
while IFS= read -r line; do
  # Wi-Fi connection attempts
  if [[ "$line" == *'NetworkManager[770]: <info>  [1742791717.9370] device (wlp2s0): Activation: starting connection 'AM-235''* ]]; then
    wifi_connection_count=$((wifi_connection_count + 1))
  fi

  # NTP timeouts
  if [[ "$line" == *'systemd-timesyncd[760]: Timed out waiting for reply from'* ]]; then
    ntp_timeout_count=$((ntp_timeout_count + 1))
  fi

  # Fingerprint errors
  if [[ "$line" == *'gnome-shell[1153]: JS ERROR: Failed to initialize fprintd service: Gio.IOErrorEnum: GDBus.Error:net.reactivated.Fprint.Error.NoSuchDevice: No devices available'* ]]; then
    fingerprint_error=1
  fi

    #Apparmor denials
  if [[ "$line" == *'apparmor="DENIED"'* ]]; then
    apparmor_denied_count=$((apparmor_denied_count + 1))
  fi

  # kerneloops errors
  if [[ "$line" == *'kerneloops.service: Found left-over process'* ]]; then
    kerneloops_error=1
  fi

  # NetworkManager state changes
  if [[ "$line" == *'NetworkManager[770]: <info>  [1742791718.'* ]]; then
      if [[ "$line" == *'state change:'* ]]; then
          network_manager_state_changes+=("$line")
          state=$(echo "$line" | grep -o "state change: [a-z-]*" | cut -d ':' -f 2 | xargs)
          network_manager_states+=("$state")
      fi
  fi

  # Services starting
  if [[ "$line" == *'systemd[1]: Starting '* ]]; then
    service=$(echo "$line" | grep -o "Starting [a-zA-Z0-9.-]*" | cut -d ' ' -f 2)
    services_started+=("$service")
  fi

  # Services failing
  if [[ "$line" == *'Activated service '*failed* ]]; then
    service=$(echo "$line" | grep -o "Activated service '[a-zA-Z0-9.-]*' failed" | cut -d "'" -f 2)
    services_failed+=("$service")
  fi

  # Services deactivating
  if [[ "$line" == *'Deactivated successfully.'* ]]; then
    service=$(echo "$line" | grep -o "[a-zA-Z0-9.-]*.service: Deactivated successfully." | cut -d ':' -f 1)
    services_deactivated+=("$service")
  fi

  # Device errors
  if [[ "$line" == *'not supported by any plugin'* ]]; then
    device=$(echo "$line" | grep -o "'/sys/devices/[^']*'" | cut -d "'" -f 2)
    device_errors+=("$device")
  fi

done < "$log_file"

# Output usage data
echo "Log File Analysis:"
echo "-------------------"
echo "Wi-Fi Connection Attempts: $wifi_connection_count"
echo "NTP Timeout Count: $ntp_timeout_count"
if [[ "$fingerprint_error" -eq 1 ]]; then
  echo "Fingerprint Device Error: Yes"
else
  echo "Fingerprint Device Error: No"
fi
echo "AppArmor Denied Count: $apparmor_denied_count"

if [[ "$kerneloops_error" -eq 1 ]]; then
  echo "Kerneloops Error: Yes"
else
  echo "Kerneloops Error: No"
fi

echo ""
echo "NetworkManager State Changes:"
for state in "${network_manager_states[@]}"; do
  echo "  - $state"
done

echo ""
echo "Services Started:"
for service in "${services_started[@]}"; do
  echo "  - $service"
done

echo ""
echo "Services Failed to Start:"
for service in "${services_failed[@]}"; do
  echo "  - $service"
done

echo ""
echo "Services Deactivated:"
for service in "${services_deactivated[@]}"; do
  echo "  - $service"
done

echo ""
echo "Device Errors:"
for device in "${device_errors[@]}"; do
  echo "  - $device"
done
