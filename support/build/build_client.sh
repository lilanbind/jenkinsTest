#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $THIS_DIR/build_util.sh



build_target() {

	set_active_configuration "$1" "$2"
	
	pushd $BASE_DIR
	
	$BUILD_DIR/prepare_build_content_pc.sh
	
	echo "About to build client for: $PLATFORM $CONFIGURATION"
	COMMAND_BASE="$UNITY_EDITOR -batchmode -quit -projectPath $WIZZTOOL_DIR -executeMethod "

	# Unity needs to switch platforms and build separately
	# in order to avoid build layout errors between editor and player
	
	SWITCH_COMMAND="BuildManager.SwitchTo$PLATFORM$CONFIGURATION"
	# something strange is happening with log files at the moment...
	# pathes don't seem to work
	COMMAND="$COMMAND_BASE $SWITCH_COMMAND -logFile $LOG_FILE_NAME"
	echo "UNITY SWITCH COMMAND: $COMMAND"
	$COMMAND
	SWITCH_ERR=$?	
	
	if [[ $SWITCH_ERR -eq 0 ]]; then
		BUILD_COMMAND="BuildManager.Build$PLATFORM$CONFIGURATION"
		#ditto
		COMMAND="$COMMAND_BASE $BUILD_COMMAND -logFile $LOG_FILE_NAME"
		echo "UNITY BUILD COMMAND: $COMMAND"
		$COMMAND
		BUILD_ERR=$?
	fi	

	mv $LOG_FILE_NAME $OUTPUT_DIR
	if [[ $SWITCH_ERR -ne 0 || $BUILD_ERR -ne 0 || ! -d $TARGET_APP_DIR ]]; then
		CAT_BUILD_LOG_COMMAND="cat $LOG_FILE_PATH"
		echo "\n\n\n\nUnity build build failure.\n\n\n\nBuild log:\n\n ( $CAT_BUILD_LOG_COMMAND ): "
		$CAT_BUILD_LOG_COMMAND
		exit_error "Building for $PLATFORM $CONFIGURATION failed"
	fi
	
	post_process_build
	
	popd
}

post_process_build() {
	
	if [[ $PLATFORM == "MacOSX" ]]; then
		post_process_MacOSX
	elif [[ $PLATFORM == "Windows" ]]; then
		post_process_Windows
	fi
}

remove_meta_files() {
	find $TARGET_DIR -name "*.meta" -type f -delete
}

post_process_MacOSX() {
	if [[ $PLATFORM != "MacOSX" ]]; then
		exit_error "Internal error: platform mismatch - MacOSX vs. $PLATFORM" 
	fi
	
	
	export FULL_APP_NAME=${APP_NAME}.app	
	export FULL_APP_PATH="$TARGET_DIR/$FULL_APP_NAME"

	copy_MacOSX_plist
	remove_meta_files
}


post_process_Windows() {
	if [[ $PLATFORM != "Windows" ]]; then
		exit_error "Internal error: platform mismatch - Windows vs. $PLATFORM" 
	fi
	
	MSVCR_DLL_PATH="$BUILD_DIR/installer/Windows/resources/msvcr100.dll"
	cp $MSVCR_DLL_PATH $TARGET_DIR
	report_error_and_exit "Copying msvcr DLL file failed"

	HELPERS_SRC_PATH="$BUILD_DIR/installer/Windows/helpers/*.exe"
	HELPERS_DST_PATH="$TARGET_DIR/${APP_NAME}_Data/bin"
	mkdir $HELPERS_DST_PATH
	
	cp $HELPERS_SRC_PATH "$HELPERS_DST_PATH"
	report_error_and_exit "Copying Windows helper files failed"
	
}


if [ ! -x "$UNITY_EDITOR" ]; then
	echo "####################################################"
	echo "###"
	echo "### UNITY_EDITOR does not point to a valid executable. Make sure you define UNITY_EDITOR to point to your Unity editor path"
	echo "### e.g. export UNITY_EDITOR=/Applications/Unity/Unity.app/Contents/MacOS/Unity"
	echo "###"
	echo "####################################################"
	exit 1
fi


if [[ $# -ne 0 && $# -ne 2 ]]; then
	exit_error "USAGE: build_client.sh [platform configuration]"
fi


##


if [[ $# -eq 2 ]]; then
	
	check_platform $1
	check_configuration $2
	build_target $1 $2
	
else
	
	for bp in "${VALID_PLATFORMS[@]}" ; do
		
		PLATFORM_BUILD_FLAG=BUILD_$bp
		FLAG_VALUE=$(eval echo \$$PLATFORM_BUILD_FLAG)
		echo "BUILD_FLAG for platform $bp is: $PLATFORM_BUILD_FLAG = $FLAG_VALUE"
		if [[ "$FLAG_VALUE" == "false" ]]; then
			echo "Ignoring build for platform: $bp"
		else
			for bc in "${DEFAULT_CONFIGURATIONS[@]}" ; do

				CONFIG_BUILD_FLAG=BUILD_$bc
				FLAG_VALUE=$(eval echo \$$CONFIG_BUILD_FLAG)
				echo "BUILD_FLAG for configuration $bc is: $CONFIG_BUILD_FLAG = $FLAG_VALUE"
				if [[ "$FLAG_VALUE" == "false" ]]; then
					echo "Ignoring $bp build for configuration: $bc"
				else
					build_target $bp $bc
				fi
				
			done
		fi
	done	
	
fi


report_success


