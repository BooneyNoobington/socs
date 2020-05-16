#!/bin/bash
################################################################################
### Script to automate software installation ###################################
################################################################################
#
### Preparations ###
SCRIPTNAME="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"  # Name
                                                         # of the script itself.
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  # Store the name of
                                     #the directory the script is executed from.
export BASEDIR SCRIPTNAME # Export the base directory path and SCRIPTNAME.
source "$BASEDIR/Libraries/functions"  # Source some functions.
source "$BASEDIR/Configuration/shell configurations"  # Source some configs.
#
. "$BASEDIR/Configuration/binpaths.sh" package  # Get information about the
                                       # systems package management system.
#
## Get command line options ##
while getopts ':b' OPTION ; do
  case $OPTION in
  # Download in background?
  b) background="yes" ;;
  \?) echo "Unbekannte Option \"-$OPTARG\"." >&2
  usage $EXIT_ERROR ;;
  :) echo "Option \"-$OPTARG\" benötigt ein Argument." >&2
  usage $EXIT_ERROR ;;
  *) echo "Dies kann eigentlich gar nicht passiert sein..." >&2
  usage $EXIT_BUG ;;
  esac
done
shift $(( OPTIND - 1 ))  # Skip used option arguments.
#
### Check wehter this script should be run in the background ###
if [[ $background == "yes" ]]; then
  # Check if screen is even installed.
  check_and_install screen
  # Reopen this very script but in background.
  YET_TO_INSTALL=$@  # Form and export a variable containing the packages to
                     # install.
  export YET_TO_INSTALL
  "$SCREEN_BIN" -a -S "$SCRIPTNAME_`sorting_date`" bash -c '"$BASEDIR/$SCRIPTNAME" $YET_TO_INSTALL; read -n 1 -p "The script came to an end. Press any key to continue..."'
  # Quit this instance of the script.
  exit 0
fi
#
### Installation process ###
#
## Update repos ##
if [[ "$UPDATE_CMD" != '' ]]; then  # There is a update Command.
  socs_echo "$SCRIPTNAME" "Updating the repos..."
  sudo $PACKAGE_MANAGER $UPDATE_CMD
fi
#
## Upgrade the system ##
socs_echo "$SCRIPTNAME" "Updating the system..."
sudo $PACKAGE_MANAGER $UPGRADE_CMD  # Perform upgrading process.
#
for ARG; do  # For each given argument, try to install it.
  sudo $PACKAGE_MANAGER $INSTALL_CMD $ARG  # Via the appropriate command.
done
