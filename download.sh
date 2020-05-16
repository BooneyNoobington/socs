#!/bin/bash
################################################################################
### Script for automated downloading of various filetypes ######################
### e.g. videos, torrents or "regular" downloads ################################
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
# Dot for execution inside the same shell.
#
## Default values ##
#
## Get command line options ##
while getopts ':bt:d:' OPTION ; do
  case $OPTION in
  # Download in background?
  b) background="yes" ;;
  t) TYPE="$OPTARG" ;;  # Option to provide the script with the downloadtype.
  d) DOWNLOAD_DIR="$OPTARG" ;;
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
if (( $# < 1 )) ; then  # Test for minimal argument count.
  echo "Please provide a download link." >&2
  usage $EXIT_ERROR
fi
#
### Check wehter this script should be run in the background ###
if [[ $background == "yes" ]]; then
  # Check if screen is even installed.
  check_and_install screen
  # Reopen this very script but in background.
  "$SCREEN_BIN" -a -S "download_`sorting_date`" "$BASEDIR/download" -t $TYPE -d "$DOWNLOAD_DIR" $1
  # Quit this instance of the script.
  exit 0
fi
## Taking input ##
#
### Firing up subsequent scripts ###
#
## Choose a subsequent script according to download type ##
case $TYPE in
  ## A regular download ##
  file) if [[ $DOWNLOAD_DIR == '' ]]; then DOWNLOAD_DIR="$HOME/Downloads/"; fi
        # A regular download is best stored in the Downloads-directory.
        socs_echo "$SCRIPTNAME" "Downloading file to ${bold}$DOWNLOAD_DIR${normal}"
        # Start a download with wget. Set the prefix to the disered download
        # directory.
        # Check if wget is even installed.
        check_and_install wget
        "$WGET_BIN" --directory-prefix="$DOWNLOAD_DIR" $1 ;;
  ## A torrent download ##
  torrent) if [[ $DOWNLOAD_DIR == '' ]]; then DOWNLOAD_DIR="$HOME/Downloads/"; fi
           socs_echo "$SCRIPTNAME" "Downloading torrent to ${bold}$DOWNLOAD_DIR${normal}"
           # Chec if transmission-cli is even available.
           check_and_install transmission-cli
           "$TRANSMISSION_CLI_BIN" --finish "$BASEDIR/Auxiliary Scripts/killtr.sh" $1 ;;
  ## Download from a streaming site ##
  video) if [[ $DOWNLOAD_DIR == '' ]]; then DOWNLOAD_DIR="$HOME/Videos/"; fi
         socs_echo "$SCRIPTNAME" "Downloading video stream to ${bold}$DOWNLOAD_DIR${normal}"
         # If no download directory was specified, use "Videos".
         # Check if youtube-dl is even installed.
         . "$BASEDIR/Configuration/binpaths.sh" youtube-dl
         "$YOUTUBE_DL_BIN" --update --output "$DOWNLOAD_DIR""%(title)s.%(ext)s" "$1" ;;
         # Call the youtube-dl-script and update first.
  ## Unknown option ##
  \?) echo "Unknow download type \"$TYPE\"." ;;
esac
### The End ###
exit 0
