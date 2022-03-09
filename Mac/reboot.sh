#!/usr/bin/env zsh

## Optional arguments (for testing):
## -v Overrides actual version of the MacOS
## -m Specify target latest Monterey version
## -b Specify target latest Big Sur version
## -c Specify target latest Catalina version


# Defaults for currently latest versions of each supported MacOS
ACTUAL=$(sw_vers -productVersion)
LATEST_MONTEREY="12.2.1"
LATEST_BIGSUR="11.6.4"
LATEST_CATALINA="10.15.7"

while getopts v:lm:lb:lc: flag
do
    case "${flag}" in
        v) ACTUAL=${OPTARG:-$(sw_vers -productVersion)};;
        m) LATEST_MONTEREY=${OPTARG:-$LATEST_MONTEREY};;
        b) LATEST_BIGSUR=${OPTARG};;
        c) LATEST_CATALINA=${OPTARG};;
    esac
done
echo $LATEST_MONTEREY
# IBM Notifier binary paths
NA_PATH="/Applications/Pixel Notifier.app/Contents/MacOS/Pixel Notifier"

# Variables for the popup notification for ease of customization

# This check whether the plist counter exists, creates with zero count if not. 
# $(/usr/libexec/PlistBuddy -c 'print ":name"' 
# defaults read com.pixelmachinery.notifier popup_count
# POPUP_COUNTER_CMD="bash -c `defaults read com.pixelmachinery.notifier popup_count`"
# echo "$($POPUP_COUNTER_CMD)"

autoload is-at-least



LATEST_MONTEREY_BUILD="21D62"
LATEST_BIGSUR_BUILD="20G417"
LATEST_CATALINA_BUILD="19H1715"

TARGET_VERSION=""

### FUNCTIONS ###

upgrade_check() {

    

    PATH="/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin"

            # this will check to make sure `sw_vers` exists
            # if it does not, this is probably not macOS
    if ((! $+commands[sw_vers] ))
    then
            echo "$NAME: 'sw_vers' is required but not found in $PATH" >>/dev/stderr
            exit 2
    fi
            ## "Is the version of macOS that we are using _at least_ 10.16?"
    if [[ "$ACTUAL" == 10.15.* ]]; then
        # echo "macOS Catalina - $ACTUAL"
        if is-at-least "$LATEST_CATALINA" "$ACTUAL"; then
            # echo "We're on latest version - $LATEST_CATALINA"
            echo "0"
        else
            # echo "Not on latest, should upgrade to - $LATEST_CATALINA"
            echo $LATEST_CATALINA_BUILD
        fi
    elif [[ "$ACTUAL" == 11.* ]]; then
        # echo "macOS Big Sur - $ACTUAL"
        if is-at-least "$LATEST_BIGSUR" "$ACTUAL"; then
            # echo "We're on latest version - $LATEST_BIGSUR"
            echo "0"
        else
            # echo "Not on latest, should upgrade to - $LATEST_BIGSUR"
            echo $LATEST_BIGSUR_BUILD
        fi
    elif [[ "$ACTUAL" == 12.* ]]; then
        # echo "macOS Monterey - $ACTUAL"
        if is-at-least "$LATEST_MONTEREY" "$ACTUAL"; then
            # echo "We're on latest version - $LATEST_MONTEREY"
            echo "0"
        else
            # echo "Not on latest, should upgrade to - $LATEST_MONTEREY"
            echo $LATEST_MONTEREY_BUILD
        fi
    else
        # echo "(Mac) OS X something -- probably pre-catalina"
        echo "1"
    fi
}

return_target_version() {
    if [[ "$ACTUAL" == 10.15.* ]]; then
        # echo "macOS Catalina - $ACTUAL"
        if is-at-least "$LATEST_CATALINA" "$ACTUAL"; then
            # echo "We're on latest version - $LATEST_CATALINA"
            echo "0"
        else
            # echo "Not on latest, should upgrade to - $LATEST_CATALINA"
            echo $LATEST_CATALINA
        fi
    elif [[ "$ACTUAL" == 11.* ]]; then
        # echo "macOS Big Sur - $ACTUAL"
        if is-at-least "$LATEST_BIGSUR" "$ACTUAL"; then
            # echo "We're on latest version - $LATEST_BIGSUR"
            echo "0"
        else
            # echo "Not on latest, should upgrade to - $LATEST_BIGSUR"
            echo $LATEST_BIGSUR
        fi
    elif [[ "$ACTUAL" == 12.* ]]; then
        # echo "macOS Monterey - $ACTUAL"
        if is-at-least "$LATEST_MONTEREY" "$ACTUAL"; then
            # echo "We're on latest version - $LATEST_MONTEREY"
            echo "0"
        else
            # echo "Not on latest, should upgrade to - $LATEST_MONTEREY"
            echo $LATEST_MONTEREY
        fi
    else
        # echo "(Mac) OS X something -- probably pre-catalina"
        echo "1"
    fi
}

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
        ${sec_button[@]} \
        -always_on_top \
        -accessory_view_type timer \
        -accessory_view_payload "Time left until restart: %@" -timeout 5000
        )

    echo "$?"
}

### END FUNCTIONS ###

# Check if update is needed...
UPGRADE_COMMAND=$(upgrade_check)
echo "$UPGRADE_COMMAND"
if [ ! "$UPGRADE_COMMAND" = "0" ]; then
    target_ver="$(return_target_version)"
    echo "Running upgrade logic, upgrading from $ACTUAL to $target_ver with build $UPGRADE_COMMAND."

    if [ $(defaults read com.pixelmachinery.notifier popup_count) ]; then
        POPUP_COUNTER=$(defaults read com.pixelmachinery.notifier popup_count)
        echo "Popup counter plist found with value ${POPUP_COUNTER}"
    else
        echo "Popup counter plist not found, creating with zero count..."
        defaults write com.pixelmachinery.notifier popup_count 0
        POPUP_COUNTER=$(defaults read com.pixelmachinery.notifier popup_count)
    fi
    echo "Current count is: ${POPUP_COUNTER}"

    NEW_COUNTER=$((POPUP_COUNTER+1))


    COUNTER_LIMIT=2
    POSTPONES_LEFT=$((COUNTER_LIMIT-POPUP_COUNTER))
    WINDOWTYPE="popup"
    BAR_TITLE="Pixel Machinery Notification"
    TITLE="Reboot required"
    TIMEOUT="" # leave empty for no notification time
    BUTTON_1="Update & Restart Now"
    BUTTON_2="Postpone one day (${POSTPONES_LEFT} left)"
    SUBTITLE="
Your Mac needs to be restarted to apply important updates  (from ${ACTUAL} to ${target_ver}). Please save your work and restart at your earliest convenience. 

Note that the update process may take up to an hour, please make sure your laptop is plugged in to power.
"

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
else 
    echo "Current version ($ACTUAL) matches target version ($(return_target_version)) - nothing to do."
fi
