#!/bin/bash
################################################################################
### Simple script to quit transmission after successfull download ##############
################################################################################
#
SCRIPTNAME="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"  # Name
                                                         # of the script itself.
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  # Store the name of
                                     #the directory the script is executed from.
source "$BASEDIR/../Libraries/functions"  # Source some functions.
source "$BASEDIR/../Configuration/shell configurations"  # Source some configs.
#
# Check wether transmission-cli is running ##
if [[ `ps -ef | grep transmission-cli | grep -v "grep"` != '' ]]; then
  killall transmission-cli
else
  socs_echo "$SCRIPTNAME" "Transmission wasn't even running."
fi
