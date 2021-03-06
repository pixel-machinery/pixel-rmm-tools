#!/usr/bin/env zsh

## Optional arguments
#  "--lm VERSION            specify latest Monterey version to check against"
#  "--tm BUILD_NUMBER       specify latest Monterey build to use"
#  "--lb VERSION            specify latest Big Sur version to check against"
#  "--tb BUILD_NUMBER       specify latest Big Sur build to use"
#  "--lc VERSION            specify latest Catalina version to check against"
#  "--tc BUILD_NUMBER       specify latest Catalina build to use"

# Defaults for currently latest versions of each supported MacOS
ACTUAL=$(sw_vers -productVersion)
LATEST_MONTEREY="12.3"
LATEST_BIGSUR="11.6.5"
LATEST_CATALINA="10.15.7"

LATEST_MONTEREY_BUILD="21E230"
LATEST_BIGSUR_BUILD="20G527"
LATEST_CATALINA_BUILD="19H1715"

while test $# -gt 0; do
  case "$1" in
    -h|--help)
      echo "options:"
      echo "-h, --help                show brief help"
      echo "--lm VERSION            specify latest Monterey version to check against"
      echo "--tm BUILD_NUMBER       specify latest Monterey build to use"
      echo "--lb VERSION            specify latest Big Sur version to check against"
      echo "--tb BUILD_NUMBER       specify latest Big Sur build to use"
      echo "--lc VERSION            specify latest Catalina version to check against"
      echo "--tc BUILD_NUMBER       specify latest Catalina build to use"
      exit 0
      ;;
    --lm*)
      shift
      echo "Latest Monterey version provided: $1"
      LATEST_MONTEREY=$1
      shift
      ;;
    --lb*)
      shift
      echo "Latest Big Sur version provided: $1"
      LATEST_BIGSUR=$1
      shift
      ;;
    --lc*)
      shift
      echo "Latest Catalina version provided: $1"
      LATEST_CATALINA=$1
      shift
      ;;
    --tm*)
      shift
      echo "Latest Monterey build number provided: $1"
      LATEST_MONTEREY_BUILD=$1
      shift
      ;;
    --tb*)
      shift
      echo "Latest Big Sur build number provided: $1"
      LATEST_BIGSUR_BUILD=$1
      shift
      ;;
    --tc*)
      shift
      echo "Latest Catalina build number provided: $1"
      LATEST_CATALINA_BUILD=$1
      shift
      ;;
    *)
      break
      ;;
  esac
done
echo $LATEST_MONTEREY
# IBM Notifier binary paths -- need to check if this exists, install otherwise
NA_PATH="/Applications/Pixel Notifier.app/Contents/MacOS/Pixel Notifier"

autoload is-at-least

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
        echo $LATEST_CATALINA
    elif [[ "$ACTUAL" == 11.* ]]; then
        echo $LATEST_BIGSUR
    elif [[ "$ACTUAL" == 12.* ]]; then
        echo $LATEST_MONTEREY
    else
        # echo "(Mac) OS X something -- probably pre-catalina"
        echo "1"
    fi
}

### END FUNCTIONS ###
echo "$(date) - Upgrade logic starting."
# Check if update is needed...
UPGRADE_COMMAND=$(upgrade_check)
echo "$UPGRADE_COMMAND"
target_ver="$(return_target_version)"

## add IF statement when upgrade command is 1 -- some sort of weird thing happening
if [ ! "$UPGRADE_COMMAND" = "0" ]; then
    echo "$(date) - Checking for cached version, downloading if missing"
    curl -s https://raw.githubusercontent.com/grahampugh/erase-install/main/erase-install.sh | sudo bash /dev/stdin --force-curl --update --sameos

    cache_verified=$?
    echo "$(date) - Erase-install caching returned code: $cache_verified"
else 
    echo "$(date) - Current version (${ACTUAL}) is greater or equal to the target version (${target_ver}) - nothing to do."
fi
