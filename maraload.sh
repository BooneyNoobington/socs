#!/bin/bash
#
### Preparations ###
SCRIPTNAME="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"  # Name
                                                         # of the script itself.
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  # Store the name of
                                     #the directory the script is executed from.
export BASEDIR # Export the base directory path.
source "$BASEDIR/Libraries/functions"  # Source some functions.
# Dot for execution inside the same shell.
#
check_and_install rsync  # We'll need rsync.
#
while true; do  # Reapeat this all the time.
  "$BASEDIR/syncro" down $1  # Use the syncro-script with "down" option.
  if [ "$?" == "0" ] ; then  # Exit code was 0. Everythin's fine.
    socs_echo "$SCRIPTNAME" "rsync completed normally"
    exit
  else
    echo "$SCRIPTNAME" "Rsync failure. Backing off and retrying..."
    sleep 180  # Wait one and a half minutes and then retry.
fi
