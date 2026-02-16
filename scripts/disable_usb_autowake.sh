#!/bin/bash
# Disable USB auto-wake to prevent system waking from minor movements
# This script disables wake for USB controllers that are too sensitive

# Function to ensure wake is disabled for a specific ACPI device
ensure_wake_disabled() {
    local device=$1
    # Check if device is currently enabled
    if grep -q "^$device.*\*enabled" /proc/acpi/wakeup 2>/dev/null; then
        echo "$device" | sudo tee /proc/acpi/wakeup > /dev/null
        echo "Disabled wake for: $device"
    elif grep -q "^$device.*\*disabled" /proc/acpi/wakeup 2>/dev/null; then
        echo "Wake already disabled for: $device"
    fi
}

# Function to ensure wake is enabled for a specific ACPI device
ensure_wake_enabled() {
    local device=$1
    # Check if device is currently disabled
    if grep -q "^$device.*\*disabled" /proc/acpi/wakeup 2>/dev/null; then
        echo "$device" | sudo tee /proc/acpi/wakeup > /dev/null
        echo "Enabled wake for: $device"
    elif grep -q "^$device.*\*enabled" /proc/acpi/wakeup 2>/dev/null; then
        echo "Wake already enabled for: $device"
    fi
}

# Enable wake for XHC1 (Logitech keyboard/mouse receiver)
ensure_wake_enabled "XHC1"

# Disable wake for other USB controllers
ensure_wake_disabled "XHC0"
ensure_wake_disabled "XHC2"
ensure_wake_disabled "XH00"

# Also disable GPU and PCIe wake sources that might cause spurious wakes
ensure_wake_disabled "GP17"
ensure_wake_disabled "GPP0"
ensure_wake_disabled "GPP7"

# Disable DisplayPort and PCIe controllers
ensure_wake_disabled "UP00"
ensure_wake_disabled "DP00"
ensure_wake_disabled "DP40"
ensure_wake_disabled "DP48"
ensure_wake_disabled "DP50"
ensure_wake_disabled "DP58"
ensure_wake_disabled "DP60"
ensure_wake_disabled "DP68"

echo "USB auto-wake configured"
echo "Current wake sources:"
grep "XHC\|GP" /proc/acpi/wakeup
