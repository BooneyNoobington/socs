#!/bin/bash
################################################################################
### Script that executes other scripts in the background #######################
################################################################################
#
### Preparations ###
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  # Store the name of
                                     #the directory the script is executed from.
export BASEDIR # Export the base directory path.
source "$BASEDIR/Libraries/functions"  # Source some functions.
### Checks ###
if (( $# < 1 )) ; then  # Test for minimal argument count.
  echo "Please provide a script and it's mandatory arguments." >&2
  usage $EXIT_ERROR
fi
#
### Provide some commands ###
# Check if screen is even installed.
. "$BASEDIR/Configuration/binpaths.sh" screen
# Execute a given script inside a screen.
"$SCREEN_BIN" -a -S "$1_`sorting_date`" "$BASEDIR/"$1 $2
