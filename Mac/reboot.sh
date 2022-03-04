#!/bin/bash

# IBM Notifier binary paths
NA_PATH="/Applications/Pixel Notifier.app/Contents/MacOS/Pixel Notifier"

# Variables for the popup notification for ease of customization

# TODO check if this exists, if not set to 0
POPUP_COUNTER_CMD="defaults read com.pixelmachinery.notifier popup_count"
# echo $($POPUP_COUNTER_CMD)
if ($POPUP_COUNTER_CMD) > /dev/null 2>&1; then
    POPUP_COUNTER=$($POPUP_COUNTER_CMD)
    echo "Popup counter plist found with value ${POPUP_COUNTER}"
else
    echo "Popup counter plist not found, creating with zero count..."
    defaults write com.pixelmachinery.notifier popup_count 0
    POPUP_COUNTER=$($POPUP_COUNTER_CMD)
fi

echo "Current count is: ${POPUP_COUNTER}"
COUNTER_LIMIT=2
POSTPONES_LEFT=$((COUNTER_LIMIT-POPUP_COUNTER))
WINDOWTYPE="popup"
BAR_TITLE="Pixel Machinery Notification"
TITLE="Reboot required"
TIMEOUT="" # leave empty for no notification time
BUTTON_1="Update & Restart Now"
BUTTON_2="Postpone one day (${POSTPONES_LEFT} left)"
SUBTITLE="Your Mac needs to be restarted to apply important updates. Please save your work and restart at your earliest convenience. 

Note that the update process may take up to an hour, please make sure your laptop is plugged in to power."

### FUNCTIONS ###

prompt_user() {
    # This will call the IBM Notifier Agent
    if [[ "${POSTPONES_LEFT}" -ge 1 ]]; then
        sec_button=("-secondary_button_label" "${BUTTON_2}")
    fi
    button=$("${NA_PATH}" \
        -type "${WINDOWTYPE}" \
        -bar_title "${BAR_TITLE}" \
        -title "${TITLE}" \
        -subtitle "${SUBTITLE}" \
        -timeout "${TIMEOUT}" \
        -main_button_label "${BUTTON_1}" \
        "${sec_button[@]}" \
        -always_on_top \
        -accessory_view_type timer \
        -accessory_view_payload "Time left until restart: %@" -timeout 500
        )

    echo "$?"
}

### END FUNCTIONS ###

# Example 1 button prompt

# Example 2 button prompt
NEW_COUNTER=$((POPUP_COUNTER+1))

RESPONSE=$(prompt_user)
echo "$RESPONSE"
if [ $RESPONSE -eq "0" ]; then
    echo "Reboot button pressed"
    echo "Resetting counter to 0"
    defaults write com.pixelmachinery.notifier popup_count 0
elif [ $RESPONSE -eq "2" ]; then
    echo "Postpone button pressed."
    defaults write com.pixelmachinery.notifier popup_count $NEW_COUNTER
else
    echo "Time ran out, forcing reboot."
    echo "Resetting counter to 0"
    defaults write com.pixelmachinery.notifier popup_count 0
fi