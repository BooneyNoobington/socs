#!/bin/bash
################################################################################
### Script to automate the socs sownload script ################################
################################################################################
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
### Options ###
while getopts ':b' OPTION ; do
  case $OPTION in
    # Execution in Background.
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
if (( $# < 1 )) ; then  # Test for minimal argument count.
  echo "Please provide a file containing download links." >&2
  usage $EXIT_ERROR
fi
#
### Check wehter this script should be run in the background ###
if [[ $background == "yes" ]]; then
  # Check if screen is even installed.
  check_and_install screen
  # Reopen this very script but in background.
  "$SCREEN_BIN" -a -S "autoload_`sorting_date`" "$BASEDIR/autoload" $1
  # Quit this instance of the script.
  exit 0
fi
## Taking input ##
while read line; do
  eval $line  # Evaluate the line to gain given variables.
  ## What if the type wasn't given? ##
  if [[ $type == '' ]]; then
    socs_echo "$SCRIPTNAME" "Download type was not given. Guessing..."
    ## Guess if it could be a torrent? ##
    if [[ `echo $url | grep ".torrent"` != '' ]]; then  # Url contains the file
                                                      # extension of a torrent.
      type=torrent  # Guess it's a torrent.
      socs_echo "$SCRIPTNAME" "Assuming a torrent."
    fi
    ## No luck in guessing? Check wether it could be a video download ##
    if [[ $type == '' ]]; then  # The type is still undetermined.
      # Check if youtube-dl is installed.
      . "$BASEDIR/Configuration/binpaths.sh" youtube-dl
      for streamer in `"$YOUTUBE_DL_BIN" --list-extractors` ; do  # Compare
      # every extractor with the url to check wether it's a streaming site.
        if [[ `echo $url | grep -i $streamer` != '' ]]; then
          type=video  # Guess it's a stream.
          socs_echo "$SCRIPTNAME" "Assuming streaming site $streamer as host."
        fi
      done
    fi

    ## Still no luck? ##
    if [[ $type == '' ]]; then
      socs_echo "$SCRIPTNAME" "Assuming a generic file download."
      type=file  # Then assume a file.
    fi
  fi
  #
  "$BASEDIR/download" -d "$target" -t "$type" "$url"  # Call the script.
  sleep 10  # Wait a few secings.
done < $1
### The End ###
exit 0
