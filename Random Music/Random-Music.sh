#!/bin/bash

# Random-Music.sh
# Creator: Inameiname
# Initial Command Creator: nothingspecial
# Original 'Music Shuffle' Creator: VH-BIL & Me
# Version: 1.0
#
# Requires mplayer: sudo apt-get install mplayer
#
# Directions:
# - Put this script inside your ~/.gnome/nautilus-scripts folder
# - Once inside your nautilus-scripts folder, it can be run one of two ways:
# - 1. - right click any folder and it will automatically randomly play any music/video inside it
# - 2. - if nothing is selected when running the script, it will default to this script's preset locations


# Set IFS so that it won't consider spaces as entry separators.
# Without this, spaces in file/folder names can make the loop go wacky.
IFS=$'\n'

# See if the Nautilus environment variable is empty
if [ -z $NAUTILUS_SCRIPT_SELECTED_FILE_PATHS ]; then
    # ================================================================================
    #    Project      : Music Shuffle
    #    Author       : VH-BIL & Me
    #    Date         : 10th Nov 2009 & 9th Sep 2010
    #    Info         :
    # The "DestPath" variable holds the path of where to write all the
    # playlists.
    #
    # The variable "MixedDestPath" holds the path and filename for the playlist
    # of the mixed Music.
    #
    # The "Music_Count" variable is then number of individual Music files to be
    # displayed in the menu.
    #
    # Arrays "Music_Name" and "Music_Path" hold information about the Music files in
    # the menu. "Music_Name" is the name of the Music file and "Music_Path" is the path
    # to where all the Music is stored. The number of Music files must
    # be recorded in "Music_Count"
    #
    # The "Mixed_Count" variable is the number of Music files to be put combined
    # into the mixed Music playlist.
    #
    # Just like the "Music_Name" and "Music_Path" variables the "Mixed_Name" and
    # Mixed_Path hold the name and file path of the Music files to be in the
    # mixed Music playlist.
    #
    # This is one of the first scripts I have made. I work as a programmer
    # but as a C# programmer. I wanted an easy way of playing my Music files shuffled
    # while not having to update playlists when adding new .
    # ================================================================================

    tty -s; if [ $? -ne 0 ]; then gnome-terminal -e "$0"; rm -R $HOME/.gnome2/nautilus-scripts/.playlists/; exit; fi

    # The Destination Path Of All The Playlists
    DestPath="$HOME/.gnome2/nautilus-scripts/.playlists/"
    # The Path And Filename Of The Mixed Music Playlist
    MixedDestPath="$HOME/.gnome2/nautilus-scripts/.playlists/MixedMusic.plist"

    mkdir $DestPath && touch $HOME/.gnome2/nautilus-scripts/.playlists/MixedMusic.plist && touch $HOME/.gnome2/nautilus-scripts/.playlists/"My Music Library (on PC)".plist && touch $HOME/.gnome2/nautilus-scripts/.playlists/"My Music Library (on external hard drive)".plist

    # Colour Codes
    black='\E[30;40m'
    red='\E[31;40m'
    green='\E[32;40m'
    yellow='\E[33;40m'
    blue='\E[34;40m'
    magenta='\E[35;40m'
    cyan='\E[36;40m'
    white='\E[37;40m'

    # My Music Libraries
    Music_Count=2 # change if need be
    Music_Name[0]="My Music Library (on PC)"
    Music_Path[0]="$HOME/Music/"
    Music_Name[1]="My Music Library (on external hard drive)"
    Music_Path[1]="/media/path/to/your/drive/and/folder/"
#     Music_Name[2]=""
#     Music_Path[2]="/media/path/to/your/drive/and/folder/"
#     Music_Name[3]=""
#     Music_Path[3]="/media/path/to/your/drive/and/folder/"
#     Music_Name[4]=""
#     Music_Path[4]="/media/path/to/your/drive/and/folder/"
#     Music_Name[5]=""
#     Music_Path[5]="/media/path/to/your/drive/and/folder/"
#     Music_Name[6]=""
#     Music_Path[6]="/media/path/to/your/drive/and/folder/"
#     Music_Name[7]=""
#     Music_Path[7]="/media/path/to/your/drive/and/folder/"
#     Music_Name[8]=""
#     Music_Path[8]="/media/path/to/your/drive/and/folder/"
#     Music_Name[9]=""
#     Music_Path[9]="/media/path/to/your/drive/and/folder/"
#     Music_Name[10]=""
#     Music_Path[10]="/media/path/to/your/drive/and/folder/"
#     Music_Name[11]=""
#     Music_Path[11]="/media/path/to/your/drive/and/folder/"
#     Music_Name[12]=""
#     Music_Path[12]="/media/path/to/your/drive/and/folder/"
#     Music_Name[13]=""
#     Music_Path[13]="/media/path/to/your/drive/and/folder/"
#     Music_Name[14]=""
#     Music_Path[14]="/media/path/to/your/drive/and/folder/"
#     Music_Name[15]=""
#     Music_Path[15]="/media/path/to/your/drive/and/folder/"


    # Mixed Music
    Mixed_Count=2
    Mixed_Name[0]="My Music Library (on PC)"
    Mixed_Path[0]="$HOME/Music/"
    Mixed_Name[1]="My Music Library (on external hard drive)"
    Mixed_Path[1]="/media/path/to/your/drive/and/folder/"


    DisplayMenu()
    {
      echo -en $white
      clear
      echo -en $white
      echo "Music Shuffle Script"
      echo -en $red
      echo "================="
      echo
      for ((cnt=0 ; cnt<=Music_Count-1 ; cnt++))
      do
        if [ $cnt -lt 10 ]
        then
          echo -en $cyan
          echo -n "("
          echo -en $blue
          echo -n $cnt
          echo -en $cyan
          echo -n ")  "
          echo -en $white
          echo ${Music_Name[cnt]}
        else
          echo -en $cyan
          echo -n "("
          echo -en $blue
          echo -n $cnt
          echo -en $cyan
          echo -n ") "
          echo -en $white
          echo ${Music_Name[cnt]}
        fi
      done
        if [ $Music_Count -lt 10 ]
        then
          echo -en $cyan
          echo -n "("
          echo -en $blue
          echo -n $Music_Count
          echo -en $cyan
          echo -n ")  "
          echo -en $white
          echo "Mixed Music"
        else
          echo -en $cyan
          echo -n "("
          echo -en $blue
          echo -n $Music_Count
          echo -en $cyan
          echo -n ") "
          echo -en $white
          echo "Mixed Music"
        fi
        let "Music_Count += 1"
        if [ $Music_Count -lt 10 ]
        then
          echo -en $cyan
          echo -n "("
          echo -en $blue
          echo -n $Music_Count
          echo -en $cyan
          echo -n ")  "
          echo -en $white
          echo "Display Mixed Music"
        else
          echo -en $cyan
          echo -n "("
          echo -en $blue
          echo -n $Music_Count
          echo -en $cyan
          echo -n ") "
          echo -en $white
          echo "Display Mixed Music"
        fi
        let "Music_Count -= 1"
      echo
      echo -n "Make A Selection :"
    }

    DisplayMixedMusic()
    {
      echo
      for ((cnt=0 ; cnt<=Mixed_Count-1 ; cnt++))
      do
        echo -en $white
        echo ${Mixed_Name[cnt]}
      done
      echo
    }

    ShuffleEpisode()
    {
      cd /
      find "${Music_Path[$1]}" > "$DestPath${Music_Name[$1]}.plist"
      mplayer -playlist "$DestPath${Music_Name[$1]}.plist" -shuffle
    }

    MixedMusic()
    {
      echo "" > $MixedDestPath
      cd /
        for ((cnt=0 ; cnt<=Mixed_Count-1 ; cnt++))
      do
        find "${Mixed_Path[$cnt]}" > "$DestPath${Mixed_Name[$cnt]}.plist"
        echo "" > $MixedDestPath"_cat"
        cat "$DestPath${Mixed_Name[$cnt]}.plist" $MixedDestPath > $MixedDestPath"_cat"
        rm $MixedDestPath
        mv $MixedDestPath"_cat" $MixedDestPath
      done
      mplayer -playlist $MixedDestPath -shuffle
    }

    DisplayMenu
    read input

    if [ $input -eq $Music_Count ]
    then
      MixedMusic
    fi

    let "Music_Count += 1"
    if [ $input -eq $Music_Count ]
    then
      DisplayMixedMusic
    fi
    let "Music_Count -= 1"

    if [ $input -lt $Music_Count ]
    then
      ShuffleEpisode $input
    fi
fi

# Loop through the list (from either Nautilus or the command line)
for ARCHIVE_FULLPATH in $NAUTILUS_SCRIPT_SELECTED_FILE_PATHS; do
    NEWDIRNAME=${ARCHIVE_FULLPATH%.*}
    FILENAME=${ARCHIVE_FULLPATH##*/}
    NAME=${ARCHIVE_FULLPATH##*/.*}

    # open a terminal window and run the important stuff
    tty -s; if [ $? -ne 0 ] ; then gnome-terminal -e "$0"; exit; fi
    mplayer -loop 0 -quiet -shuffle -playlist <(find -L $ARCHIVE_FULLPATH -type f | egrep -i '(\.mp3|\.wav|\.flac|\.ogg|\.m4a|\.aac|\.mpa|\.mid|\.aif|\.iff|\.m3u|\.ra)')

done
