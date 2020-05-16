#!/bin/bash
################################################################################
### Script to record a tv program via dvb ######################################
################################################################################
#
### Preparations ###
SCRIPTNAME="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"  # Name
                                                         # of the script itself.
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  # Store the name of
                                     #the directory the script is executed from.
export BASEDIR # Export the base directory path.
source "$BASEDIR/Libraries/functions"  # Source some functions.
source "$BASEDIR/Configuration/shell configurations"  # Bold text, etc..
export -f socs_echo  # Export the echo-function.
#
#
## Requirements ##
check_and_install rm  # Create a variable for the path to "rm".
check_and_install gnutv  # Check wether "gnutv" is already installed.
check_and_install cat  # Where's cat?
check_and_install grep
check_and_install touch
#
## Which station to record ##
station=$1  # Use the first argument.
#
#
## How long to wait until the recording begins? ##
start_time=$2  # Starting time is the second argument.
stop_time=$3  # Stopping time is the third argument.
start_time_in_seconds=`date --date="$start_time" +%s`  # Convert to seconds.
stop_time_in_seconds=`date --date="$stop_time" +%s` # Convert to seconds.
recent_time_in_seconds=`date +%s`  # Get the recent time.
#
## Where to store the recording? ##
if [[ $4 == '' ]]; then  # No path given.
  output_path="$HOME/gnutv_recording_`date --date="$start_time" +"%Y.%m.%d_%H.%M_Uhr"`.mpg"
  # Use the home directory as default.
else
  output_path=$4  # If given, use the parsed path.
fi
#
### Sanity checks ###
if [[ $start_time_in_seconds -lt $recent_time_in_seconds ]]; then  # The start-
                                                    #ing time lies in the past.
  socs_echo "$SCRIPTNAME" "Starting time lies in the past. Aborting..."
  exit 1
fi
#
if [[ $stop_time_in_seconds -lt $start_time_in_seconds ]]; then  # The stopping
                                         # time is set befor the starting time.
  socs_echo "$SCRIPTNAME" "The stopping time is set before the starting time. Aborting..."
  exit 1
fi
#
## Test recording to determine if the given station is available ##
"$GNUTV_BIN" -timeout 1 -out file "$output_path"."test.mpg" "$station"  # Perform a short test recording.
if [[ $? == 0 ]]; then  # Success in recording.
  socs_echo "$SCRIPTNAME" "A test recording of $station was successfull. File ${bold}"$output_path"."test.mpg"${normal} will be deleted."
  "$RM_BIN" "$output_path"."test.mpg"
else  # A problem occured.
  socs_echo "$SCRIPTNAME" "During the test recording of $station an error occured."
    "$TOUCH_BIN" "$output_path"."test.mpg" > /dev/null  # Try to create a demofile.
    if [[ $? != 0 ]]; then  # This didn't work.
      socs_echo "$SCRIPTNAME" "Could not create "$output_path"."test.mpg". Is the directory available to you (writeable, existing...)?"
      exit 1
    fi
  socs_echo "$SCRIPTNAME" "This was the output of \"cat /etc/channels.conf | grep $station\""
  "$CAT_BIN" /etc/channels.conf | "$GREP_BIN" "$station"
  exit 1
fi
#if [[ `grep -E "^$station" /etc/channels.conf` == '' ]]; then  # The desired
#   # station is not listed in channels.conf and can therefore not be recorded.
#  socs_echo "$SCRIPTNAME" "The given Station ${bold}$station${normal} is not available. Aborting..."
#  exit 1
#fi
#
## Is there a recording already planned for the given time? ##
if [[ -f "$BASEDIR/Variable Data/planned recordings.txt" ]]; then
# There is a file for planned recordings.
  while read line; do  # Begin reading the file line by line.
    t0=`echo $line | awk -F "·" '{print $4}'`  # Get a variable for the starting
                                                 # time out of the written line.
    t1=`echo $line | awk -F "·" '{print $5}'`  # Get a variable for the end time
                                                      # out of the written line.
    # Chech all possible cases.
    # TODO: Maybe some are equalent.
    if [[ $stop_time_in_seconds == $t0 ]]; then
      socs_echo "$SCRIPTNAME" "Stopping time is equal to starting time of another recording."
      exit 1
    fi
    #
    if [[ $start_time_in_seconds == $t1 ]]; then
      socs_echo "$SCRIPTNAME" "Starting time is equal to stopping time of another recording."
      exit 1
    fi
    #
    if [[ $start_time_in_seconds -ge $t0 ]] && [[ $stop_time_in_seconds -le $t1 ]]; then
      socs_echo "$SCRIPTNAME" "The given time is equal to another recording or lies inside the timeframe of this recording."
      exit 1
    fi
    #
    if [[ $start_time_in_seconds -le $t0 ]] && [[ $stop_time_in_seconds -ge $t1 ]]; then
      socs_echo "$SCRIPTNAME" "The given time includes a planned recording."
      exit 1
    fi
    #
    if [[ $t0 -ge $start_time_in_seconds ]] && [[ $t0 -le $stop_time_in_seconds  ]]; then
      socs_echo "$SCRIPTNAME" "The given time overlaps with a planned recording (includes starting time of planned recording)."
      exit 1
    fi
    #
    if [[ $t1 -ge $start_time_in_seconds ]] && [[ $t1 -le $stop_time_in_seconds  ]]; then
      socs_echo "$SCRIPTNAME" "The given time overlaps with a planned recording (includes stopping time of planned recording)."
      exit 1
    fi
  done < "$BASEDIR/Variable Data/planned recordings.txt"
fi
#
check_and_install screen  # Is screen already installed?
#
## Calculate time until the recording should be starting ##
waiting_time=`expr $start_time_in_seconds - $recent_time_in_seconds`
#
## Calculate sleeping time ##
timeout=`expr $stop_time_in_seconds - $start_time_in_seconds`
#
## Write a protocol file as reference for other recordings ##
echo "$station·$start_time·$stop_time·$start_time_in_seconds·$stop_time_in_seconds" >> "$BASEDIR/Variable Data/planned recordings.txt"
#
## Export the necessary variables ##
export waiting_time timeout station output_path SCRIPTNAME start_time stop_time
#
### Start the recording ###
# Give some information.
$SCREEN_BIN -a -S "gnutv recording" bash -c '
source "$BASEDIR/Configuration/shell configurations";
socs_echo "$SCRIPTNAME" "Recording ${bold}$station${normal}";
socs_echo "$SCRIPTNAME" "Recording is set to start at: ${bold}`date --date="$start_time"`${normal}";
socs_echo "$SCRIPTNAME" "Recording is set to end at: ${bold}`date --date="$stop_time"`${normal}";
socs_echo "$SCRIPTNAME" "The recording will last for ${bold}$timeout${normal} seconds (`expr $timeout / 60` minutes).";
socs_echo "$SCRIPTNAME" "To exit this screen hit [ctrl]+a and then d.";
sleep $waiting_time # wait until the recording is set to start.;
$GNUTV_BIN -timeout $timeout -out file "$output_path" "$station";
read -n 1 -p "The script came to an end. Press any key to continue..."'
