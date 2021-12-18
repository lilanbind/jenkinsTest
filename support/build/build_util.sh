#!/bin/bash

report_success() {
	echo "###################################################################"
	echo "### $0 > SUCCESS"
	echo "### $1"
	echo "###################################################################"
	exit 0
}

exit_error() {
	ERROR=$1
	
	echo "###################################################################"
	echo "### $0 > FAILURE"
	echo "### Reason: $ERROR"
	echo "###################################################################"
	exit 1
}

report_error_and_exit() {
	if [ $? -ne 0 ]; then
		exit_error "$1"
	fi
}

check_platform() {
	for p in "${VALID_PLATFORMS[@]}" ; do
		if [[ "$p" == "$1" ]]; then
			found=true
			break
		fi
	done
	if [[ "$found" != true ]]; then
		exit_error "Invalid platform: $1"
	fi
}

check_configuration() {
	for c in "${VALID_CONFIGURATIONS[@]}" ; do
		if [[ "$c" == "$1" ]]; then
			found=true
			break
		fi
	done
	if [[ "$found" != true ]]; then
		exit_error "Invalid configuration: $1"
	fi
}

set_active_configuration() {
	export PLATFORM=$1
	export CONFIGURATION=$2
	
	check_platform "$PLATFORM"
 	check_configuration "$CONFIGURATION"
	
	echo "PLATFORM: $PLATFORM - CONFIGURATION: $CONFIGURATION"
	

	export LOG_FILE_NAME="${APP_NAME}_${PLATFORM}_${CONFIGURATION}.log"
	export LOG_FILE_PATH="$OUTPUT_DIR/$LOG_FILE_NAME"
	export TARGET_DIR="$OUTPUT_DIR/${APP_NAME}_${PLATFORM}_${CONFIGURATION}"
	if [[ $PLATFORM == "IOS" ]]; then
		export TARGET_APP_DIR="$TARGET_DIR/${APP_NAME}"
	elif [[ $PLATFORM == "MacOSX" ]]; then
		export TARGET_APP_DIR="$TARGET_DIR/${APP_NAME}.app"
	elif [[ $PLATFORM == "Windows" ]]; then
		export TARGET_APP_DIR="$TARGET_DIR/${APP_NAME}_Data"
	fi
	
	echo "LOG_FILE_NAME: $LOG_FILE_NAME"
	echo "TARGET_DIR: $TARGET_DIR"
	echo "TARGET_APP_DIR: $TARGET_APP_DIR"
}

wait_1_min_for_file() {
	FILE=$1
	x=0
	while [ "$x" -lt 60 -a ! -f "$FILE" ]; do
	        x=$((x+1))
	        sleep 1
	done
}

BUILD_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SUPPORT_DIR=$( dirname $BUILD_DIR )
BASE_DIR=$( dirname $SUPPORT_DIR )
WIZZTOOL_DIR=$BASE_DIR/T7
ASSET_DIR=$WIZZTOOL_DIR/Assets
RESOURCES_DIR=$ASSET_DIR/Resources
OUTPUT_DIR="$BASE_DIR/output"

IDENTIFIER="com.li.t7"
NUM_SIGN_RETRIES=10

VALID_PLATFORMS=( "MacOSX" "Windows" )
VALID_CONFIGURATIONS=( "Debug" "Release" )
DEFAULT_CONFIGURATIONS=( "Debug" "Release" )

if [[ -z "$APP_NAME" ]]; then
	APP_NAME=T7
fi

if [ -z "$UNITY_EDITOR" ]; then
	UNITY_EDITOR=/Applications/Unity/Unity.app/Contents/MacOS/Unity
fi



