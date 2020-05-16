#!/bin/bash
#
################################################################################
### Manage your local socs installation ########################################
################################################################################
#
### Preparations ###
SCRIPTNAME="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"  # Name
                                                         # of the script itself.
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  # Store the name of
                                     #the directory the script is executed from.
export BASEDIR # Export the base directory path.
source "$BASEDIR/Libraries/functions"  # Source some functions.
source "$BASEDIR/Configuration/shell configurations"  # Source some configs.
#
### Configuration ###
source "$BASEDIR/Configuration/socs server"  # Get the serveraddress.
#
case $1 in
  update)
  ### Update the installation ###
  check_and_install wget  # Check if we got wget.
  socs_echo "$SCRIPTNAME" "Downloading the newest version of \"socs\" to ${bold}$BASEDIR/temp/complete.zip${normal} ..."
  "$WGET_BIN" "$server/complete.zip" --directory-prefix="$BASEDIR/temp/"
  # Download the "complete.zip" archive, which includes all files from socs.
  check_and_install unzip  # Check if we got unzip.
  "$UNZIP_BIN" "$BASEDIR/temp/complete.zip" -d "$BASEDIR/temp/"
  # Unzip all files in "complete.zip" to the temp/Download subdirectory.
  socs_echo "$SCRIPTNAME" "Synchronizing your' socs installation..."
  check_and_install rsync  # Check if we got rsync.
  "$RSYNC_BIN" -avu --delete "$BASEDIR/temp/socs/" "$BASEDIR/"
  # Synchronize the newly gain files via rsync. "-avu" to update just older
  # files.
  rm -rf "$BASEDIR/temp"  # Clean up the project directory.
  ;;
  alias)
  ### Create shell aliases for all of socs main scripts ###
  all_scripts=`ls -p "$BASEDIR" | grep -v /`
  # Use ls and grep to get all files in the project directory. Directories them-
  # selves are excluded by greps reversed option "-v".
  for script in $all_scripts; do  # Loop for all scripts
    socs_echo "$SCRIPTNAME" "Generating alias for ${bold}$script${normal} in ${bold}$HOME/.bashrc${normal}"
    if [[ `grep "alias $script=\"$BASEDIR/$script\"" "$HOME/.bashrc" ` == '' ]]; then
    # Such a alias doesn't already exist.
      echo "alias $script=\"$BASEDIR/$script\"" >> "$HOME/.bashrc"
      # Write the changes to your .bashrc.
    else
      socs_echo "$SCRIPTNAME" "Alias already set. Nothing to do."
    fi
  done
  ;;
esac
