#!/bin/bash
################################################################################
### Script for backing up files on a ssh/sftp-share ############################
################################################################################
#
## Preparations ###
SCRIPTNAME="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"  # Name
                                                         # of the script itself.
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  # Store the name of
                                     #the directory the script is executed from.
export BASEDIR SCRIPTNAME # Export the base directory path and SCRIPTNAME.
source "$BASEDIR/Libraries/functions"  # Source some functions.
source "$BASEDIR/Configuration/shell configurations"  # Source some configs.
#
#
### Are all required binaries available ###
check_and_install rsync
check_and_install grep
check_and_install cut
### What to do? ###
#
if [[ $2 == '' ]]; then  # Synchronise all given directories in $SCRIPTNAME.conf
  # Collect all labels given in "syncro.conf".
  socs_echo $SCRIPTNAME "Synchronising ${bold}all${normal} items in $BASEDIR/Configuration/$SCRIPTNAME.conf"
  while read line; do  # Read the config file line by line.
    eval $line  # In the respective lines there's a variable called $label which
    # contains a short description for the item to be synced.
    labelS="$labelS $label"  # Form a new variable, called $labelS, which should
    # contain all labels in one line separeted by whitespaces. 
  done < "$BASEDIR/Configuration/$SCRIPTNAME.conf"
else  # Synchronise only a given label.
  # Look up the given label in the config file.
  eval `$GREP_BIN $2 "$BASEDIR/Configuration/$SCRIPTNAME.conf"`  # grep it.
  labelS=$label  # $labelS should now only consist of one entry.
  socs_echo $SCRIPTNAME "Synchronising ${bold}$labelS${normal} ..."
fi
#
# In both cases there should now be a variable available called "$labelS" which
# contains the items to be synched.
#
# Iterate over all labels.
#
if [[ $labelS == '' ]]; then  # No labels given.
  socs_echo $SCRIPTNAME "Warning: No syncable items were found or given. Aborting..."
  exit 1
fi
#
for item in $labelS; do
  # Read in the desired line.
  eval `$GREP_BIN $item "$BASEDIR/Configuration/$SCRIPTNAME.conf"`
  #
  ## Bisect $remote_dir ##
  username=`echo $remote_dir | $CUT_BIN -d"@" -f1`  # Username comes before @
  server=`echo $remote_dir | $CUT_BIN -d":" -f1 | $CUT_BIN -d"@" -f2`  # Server
  # between @ and first :
  port=`echo $remote_dir | $CUT_BIN -d":" -f2 | $CUT_BIN -d":" -f3`  # Port comes
  # between the two :s.
  if [[ $port == '' ]]; then  # Maybe no port was given.
    port=22  # Then set it to 22.
  fi
  path=/${remote_dir#*/}  # Use variable expansion to get the path.
  #
  # Determine the desired action.
  case $1 in  # A list of all available commands.
    up)  # Synchro from MACHINE to SERVER.
      source_dir=$local_dir  # Source for copying is local.
      target_dir=$username@$server:\""$path"\"  # Target is far far away.
      # In this case, character set conversions might be neccessary.
      if [[ `uname -s` == "Darwin" ]]; then  # Using a Mac.
        utf8_conversion="--iconv=utf8-mac,utf8"  # Some charset-conversion will be 
        # neccessary for filenames.
      fi
    ;;
    down)  # Synchro from SERVER to MACHINE.
      source_dir=$username@$server:\""$path"\"  # Source is far far away.
      target_dir=$local_dir  # Target is on the local machine.
    ;;
    cleanup)  # Compare the remote and the local directories.
      socs_echo "$SCRIPTNAME" "Comparing ${bold}$local_dir${normal} with ${bold}$remote_dir${normal}."
      $RSYNC_BIN -avun --delete --rsh="ssh -p $port" $local_dir $username@$server:$path | $GREP_BIN "deleting"
      read -p "The files shown above exist on the target but not locally. Hit [Enter] to delete or [Ctrl]+c to abort."
      $RSYNC_BIN -avu --delete --rsh="ssh -p $port" $local_dir $username@$server:$path
    ;;
    cleandown)  # Compare the local and the remote directories.
      socs_echo "$SCRIPTNAME" "Comparing ${bold}$remote_dir${normal} with ${bold}$local_dir${normal}."
      $RSYNC_BIN -avun --delete --rsh="ssh -p $port" $username@$server:$path $local_dir | $GREP_BIN "deleting"
      read -p "The files shown above exist on the target but not locally. Hit [Enter] to delete or [Ctrl]+c to abort."
      $RSYNC_BIN -avu --delete --rsh="ssh -p $port" $username@$server:$path $local_dir
    ;; 
  esac
  #
  ### Execution ###
  #
  # Sync… finally.
  if [[ $1 == "up" || $1 == "down" ]]; then  # Other options don't require synching.
    socs_echo $SCRIPTNAME "Will now sync ${bold}$source_dir${normal}"
    socs_echo $SCRIPTNAME "onto ${bold}$path${normal} ..."
    socs_echo $SCRIPTNAME "on the server ${bold}$server${normal} ..."
    socs_echo $SCRIPTNAME "via port ${bold}$port${normal} ..."
    socs_echo $SCRIPTNAME "as user ${bold}$username${normal}."
    $RSYNC_BIN -avu --progress --rsh="ssh -p $port" $additional_options $utf8_conversion "$source_dir" "$target_dir"
  fi
done
exit $?  # Exit with the most recent exit code.