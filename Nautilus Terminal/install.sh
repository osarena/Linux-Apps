#!/bin/bash

##
## This script is based on:
##
##     http://bzr.flogisoft.com/bash-install-script/
##
##
## Copyright (c) 2011 Fabien LOISON <http://www.flogisoft.com/>
##
## This program is free software. It comes without any warranty, to
## the extent permitted by applicable law. You can redistribute it
## and/or modify it under the terms of the Do What The Fuck You Want
## To Public License, Version 2, as published by Sam Hocevar. See
## http://sam.zoy.org/wtfpl/COPYING for more details.
##


##############################################################################
## Main functions                                                           ##
##############################################################################

export APP_NAME="nautilus-terminal"
export APP_DISP_NAME="Nautilus Terminal"


_install() {
	##
	## Install or package the application
	## $1 -- The "prefix" (see _package())
	##

	test -z "$1" && _title "Installing ${APP_DISP_NAME}..."

	_do mkdir -p "$1"/usr/share/nautilus-python/extensions/
	_do cp ./src/nautilus_terminal.py "$1"/usr/share/nautilus-python/extensions/

	_do mkdir -p "$1"/usr/share/nautilus-terminal/
	_do cp ./pixmap/*.png "$1"/usr/share/nautilus-terminal/

	_do mkdir -p "$1"/usr/share/doc/nautilus-terminal/
	_do cp ./AUTHORS "$1"/usr/share/doc/nautilus-terminal/
	_do cp ./COPYING "$1"/usr/share/doc/nautilus-terminal/
	_do cp ./README "$1"/usr/share/doc/nautilus-terminal/
}


_remove() {
	##
	## Remove the application from the system
	##

	_title "Removing ${APP_DISP_NAME}..."

	_do rm /usr/share/nautilus-python/extensions/nautilus_terminal.py

	_do rm -rf /usr/share/nautilus-terminal/

	_do rm /usr/share/doc/nautilus-terminal/AUTHORS
	_do rm /usr/share/doc/nautilus-terminal/COPYING
	_do rm /usr/share/doc/nautilus-terminal/README
	_do rmdir /usr/share/doc/nautilus-terminal/
}


_package() {
	##
	## Package the application (the _install function can be often used both
	##     for installing and packaging)
	## $1 -- The "prefix" (the folder where the application must be installed)
	##

	_title "Packaging ${APP_DISP_NAME} in '${1}'..."
	_install "$1" #Call the install function, with the prefix as parameter
}


_run_dep() {
	##
	## Check the runtime dependencies
	##

	_title "Checking the Runtime Dependencies..."

	_xdo "Python (>= 2.6)" python -V
	_xdo "PyGObject" python <<< "import gobject"
	_xdo "GObject Introspection (and Gtk)" python <<< "from gi.repository import Gtk, Gdk, GLib"
	_xdo "VTE" python <<< "from gi.repository import Vte"
	_xdo "Nautilus Python (>= 1.0)" python <<< "from gi.repository import Nautilus"
	_xdo "Nautilus (>= 3.0)" test -x /usr/bin/nautilus
}


##############################################################################
## Various helpers                                                          ##
##############################################################################

_init() {
	##
	## Initialize the script variables depending of the environment
	##

	export _ERROR=0
	export _LOG="/tmp/install_${APP_NAME}_$$.log"

	case $TERM in
		xterm*|screen)
			export _DUMBTERM=0
			export LINES=$(stty size | cut -d ' ' -f 1)
			export COLUMNS=$(stty size | cut -d ' ' -f 2)
			export _COLOR_SUCCESS="\e[1;37m"
			export _COLOR_INFO="\e[1;37m"
			export _COLOR_ERROR="\e[1;31m"
			export _COLOR_WARNING="\e[1;33m"
			export _COLOR_BULLET="\e[1;34m"
			export _COLOR_TITLE="\e[1;36m"
			export _COLOR_NORMAL="\e[0m"
			;;
		*)
			export _DUMBTERM=1
			export LINES=24
			export COLUMNS=80
			;;
	esac
}


_do() {
	##
	## Execute a command
	##

	#Display the command
	if [ $_DUMBTERM == 0 ] ; then
		if [ $(echo -n "$*" | wc -c) -gt $(($COLUMNS - 12)) ] ; then
			msg=$(echo "$*" | head -c $(($COLUMNS - 15)))
			echo -en "  ${_COLOR_BULLET}>${_COLOR_NORMAL} ${msg}"
			echo -en "... "
		else
			echo -en "  ${_COLOR_BULLET}>${_COLOR_NORMAL} $*"
			echo -en "\e[$(($COLUMNS - $(echo -n "$*" | wc -c) - 11))C"
		fi
	else
		echo -n "  > $* "
	fi
	#Log
	echo "  > $*" 1>> "$_LOG"
	#Exec the command and log the result
	"$@" 1>> "$_LOG" 2>> "$_LOG" \
		&& (echo -e "${_COLOR_BULLET}[${_COLOR_SUCCESS}DONE${_COLOR_BULLET}]${_COLOR_NORMAL}") \
		|| { echo -e "${_COLOR_BULLET}[${_COLOR_ERROR}FAIL${_COLOR_BULLET}]${_COLOR_NORMAL}" ; 
	        export _ERROR=$(($_ERROR + 1)); }
}


_xdo() {
	##
	## Execute a command like _do but display a custom message (usefull for depchek)
	## $1 -- The custom message
	##

	#Display the command
	if [ $_DUMBTERM == 0 ] ; then
		if [ $(echo -n "$1" | wc -c) -gt $(($COLUMNS - 12)) ] ; then
			msg=$(echo "$1" | head -c $(($COLUMNS - 15)))
			echo -en "  ${_COLOR_BULLET}>${_COLOR_NORMAL} ${msg}"
			echo -en "... "
		else
			echo -en "  ${_COLOR_BULLET}>${_COLOR_NORMAL} $1"
			echo -en "\e[$(($COLUMNS - $(echo -n "$1" | wc -c) - 11))C"
		fi
	else
		echo -n "  > $1 "
	fi
	#Log
	echo "  > $1" 1>> "$_LOG"
	echo "    $*" 1>> "$_LOG"
	#Exec the command and log the result
	shift
	"$@" 1>> "$_LOG" 2>> "$_LOG" \
		&& (echo -e "${_COLOR_BULLET}[${_COLOR_SUCCESS} OK ${_COLOR_BULLET}]${_COLOR_NORMAL}") \
		|| { echo -e "${_COLOR_BULLET}[${_COLOR_ERROR}MISS${_COLOR_BULLET}]${_COLOR_NORMAL}" ; 
	        export _ERROR=$(($_ERROR + 1)); }
}


_title() {
	##
	## Write a title
	##

	echo -e "\n${_COLOR_BULLET}::${_COLOR_TITLE} $*${_COLOR_NORMAL}\n"
	echo -e "\n:: $*\n" 1>> "$_LOG"
}


_msg() {
	##
	## Write a message
	## $1 -- Type (info, warn, error, *)
	##
	
	case "$1" in
		i|info|information)
			echo -e "${_COLOR_INFO}I:${_COLOR_NORMAL} ${2}"
			echo -e "I: $*" 1>> "$_LOG"
			;;
		w|warn|warning)
			echo -e "${_COLOR_WARNING}W:${_COLOR_NORMAL} ${2}"
			echo -e "W: $*" 1>> "$_LOG"
			;;
		e|error)
			echo -e "${_COLOR_ERROR}E:${_COLOR_NORMAL} ${2}"
			echo -e "E: $*" 1>> "$_LOG"
			;;
		*)
			echo -e "  ${_COLOR_BULLET}*${_COLOR_NORMAL} $*"
			echo -e "  * $*" 1>> "$_LOG"
			;;
	esac
}


_help() {
	#Install
	type _install 1> /dev/null 2> /dev/null && {
		echo "-i, --install:"
		echo "    Installs ${APP_DISP_NAME} on your system (need to be root)."
		echo
	}
	#Remove
	type _remove 1> /dev/null 2> /dev/null && {
		echo "-r, --remove:"
		echo "    Removes ${APP_DISP_NAME} from your system (need to be root)."
		echo
	}
	#Package
	type _package 1> /dev/null 2> /dev/null && {
		echo "-p <prefix>, --package <prefix>:"
		echo "    Packages ${APP_DISP_NAME}. <prefix> is the folder where the"
		echo "    application will be installed (the folder must exists, and"
		echo "    the path must NOT ends with a /)."
		echo
	}
	#Dependencies
	_deps=0
	type _build_dep 1> /dev/null 2> /dev/null && _deps=1
	type _run_dep 1> /dev/null 2> /dev/null && _deps=1	
	test $_deps == 1 && {
		echo "-d, --dependencies:"
		echo "    Checks if all the dependencies are satisfied."
		echo
	}
	#Locale
	type _locale 1> /dev/null 2> /dev/null && {
		echo "-l, --locale:"
		echo "    Extracts the translatable strings from the application"
		echo "    (generates the translation template .pot)"
		echo
	}
	#Help
	echo "-h, --help:"
	echo "    Display this help."
}


##############################################################################
## Main                                                                     ##
##############################################################################

cd "${0%/*}" 1> /dev/null 2> /dev/null #Go to the script folder
_init

case "$1" in
	-i|--install)
		type _install 1> /dev/null 2> /dev/null && {
			if [ $(whoami) == "root" ] ; then
				type _build_dep 1> /dev/null 2> /dev/null && _build_dep
				type _run_dep 1> /dev/null 2> /dev/null && _run_dep
				if [ $_ERROR == 0 ] ; then
					_install
				else
					_msg error "Some dependencies are missing."
					exit 1
				fi
				if [ $_ERROR == 0 ] ; then
					_msg info "${APP_DISP_NAME} was successfully installed."
					rm -rf "${_LOG}" 1> /dev/null 2> /dev/null
					exit 0
				else
					_msg error "An error occurred during the installation."
					_msg info  "Check the log for more informations: '${_LOG}'."
					exit 1
				fi
			else
				_msg error "You need to be root."
				rm -rf "${_LOG}" 1> /dev/null 2> /dev/null
				exit 1
			fi
		}
		;;
	-r|--remove)
		type _remove 1> /dev/null 2> /dev/null && {
			if [ $(whoami) == "root" ] ; then
				_remove
				if [ $_ERROR == 0 ] ; then
					_msg info "${APP_DISP_NAME} was successfully removed."
					rm -rf "${_LOG}" 1> /dev/null 2> /dev/null
					exit 0
				else
					_msg error "An error occurred when removing the application."
					_msg info  "Check the log for more informations: '${_LOG}'."
					exit 1
				fi
			else
				_msg error "You need to be root."
				rm -rf "${_LOG}" 1> /dev/null 2> /dev/null
				exit 1
			fi
		}
		;;
	-p|--package)
		type _package 1> /dev/null 2> /dev/null && {
			if [ -d "$2" ] ; then
				type _build_dep 1> /dev/null 2> /dev/null && _build_dep
				if [ $_ERROR == 0 ] ; then
					_package "$2"
					if [ $_ERROR == 0 ] ; then
						_msg info "${APP_DISP_NAME} was successfully packaged."
						rm -rf "${_LOG}" 1> /dev/null 2> /dev/null
						exit 0
					else
						_msg error "An error occurred when packaging ${APP_DISP_NAME}."
						_msg info  "Check the log for more informations: '${_LOG}'."
						exit 1
					fi
				else
					_msg error "Some dependencies are missing."
					exit 1
				fi
			else
				_msg error "'$2' is not a folder or does not exists."
				rm -rf "${_LOG}" 1> /dev/null 2> /dev/null
				exit 1
			fi
		}
		;;
	-d|--dependencies)
		_deps=0
		type _build_dep 1> /dev/null 2> /dev/null && _deps=1
		type _run_dep 1> /dev/null 2> /dev/null && _deps=1
		test $_deps == 1 && {
			type _build_dep 1> /dev/null 2> /dev/null && _build_dep
			type _run_dep 1> /dev/null 2> /dev/null && _run_dep
			exit 0
		}
		;;
	-l|--locale)
		type _locale 1> /dev/null 2> /dev/null && {
			_locale
			if [ $_ERROR == 0 ] ; then
				_msg info "Strings successfully extracted."
				rm -rf "${_LOG}" 1> /dev/null 2> /dev/null
				exit 0
			else
				_msg error "Strings extraction failed."
				_msg info  "Check the log for more informations: '${_LOG}'."
				exit 1
			fi
		}
		;;
	-h|--help)
		_help
		exit 0
		;;
esac

#No matching option, display an error
_msg error "Invalid option."
_msg info  "Use the --help option for more informations."

exit 1
