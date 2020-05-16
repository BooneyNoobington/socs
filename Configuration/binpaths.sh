#!/bin/bash
################################################################################
### Script to determine, where socs looks for binaries (local builds are  ######
### preferred) #################################################################
################################################################################
#
# This script handles special cases wich can cause problems with package
# managers.
#
case $1 in  # Select which app to check for.
#
  youtube-dl)
  if [[ ! -f "$BASEDIR/Auxiliary Scripts/youtube-dl" ]]; then
  # Youtube-dl is not available in the base directory.
    "$WGET_BIN" https://yt-dl.org/downloads/latest/youtube-dl -O "$BASEDIR/Auxiliary Scripts/youtube-dl"
    # Download it.
    chmod a+x "$BASEDIR/Auxiliary Scripts/youtube-dl"  # Make it executable.
  fi
  # Export the global shell variable.
  export YOUTUBE_DL_BIN="$BASEDIR/Auxiliary Scripts/youtube-dl"
  ;;
#
  package)
  # Check which package manager your system uses
  # Check for apt-get.
  which apt-get >/dev/null 2>&1  # Execute which and ignore the result at fist.
  if [ $? -eq 0 ]; then  # Was the error code 0, when you checked?
    PACKAGE_MANAGER=`which apt-get`  # If yes, it's apt.
    UPDATE_CMD="update"  # In case of APT the command for refreshing the repos
                                                                  # is update.
    UPGRADE_CMD="dist-upgrade -y"  # dist-upgrade updates the entire system.
    INSTALL_CMD="install -y"  # Installation requires option -y.
  fi
  # Check for apt (newer then apt-get).
  which apt >/dev/null 2>&1  # Execute which and ignore the result at fist.
  if [ $? -eq 0 ]; then  # Was the error code 0, when you checked?
    PACKAGE_MANAGER=`which apt`  # If yes, it's apt.
    UPDATE_CMD="update"  # In case of APT the command for refreshing the repos
                                                                  # is update.
    UPGRADE_CMD="dist-upgrade -y"  # dist-upgrade updates the entire system.
    INSTALL_CMD="install -y"  # Installation requires option -y.
  fi
  # Check for DNF.
  which dnf >/dev/null 2>&1  # Execute which and ignore the result at fist.
  if [ $? -eq 0 ]; then  # Was the error code 0, when you checked?
    PACKAGE_MANAGER=`which dnf`  # If yes, it's apt.
    UPDATE_CMD=""  # In case of dnf no special command for refreshing the
                                                             # repos is needed.
    UPGRADE_CMD="update --assumeyes"  # "update" updates the entire system.
    INSTALL_CMD="install --assumeyes"  # Installation requires option assumeyes.
  fi
  export UPDATE_CMD
  export UPGRADE_CMD
  export INSTALL_CMD
  export PACKAGE_MANAGER
  ;;  # Exort the global shell variable.
#
  screen)
  if [[ -f "$BASEDIR/Local Builds/screen/screen" ]]; then  # A local build
                                                       # of screen exists.
    SCREEN_BIN="$BASEDIR/Local Builds/screen/screen"
  else
    SCREEN_BIN="`which screen`"  # If not use the regularly installed
                                                               # one.
    socs_echo "binpaths.sh" "screen was set to ${bold}$SCREEN_BIN${normal}"
  fi
  export SCREEN_BIN
  ;;  # Export global shell variable
#
esac
