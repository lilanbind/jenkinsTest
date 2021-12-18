#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $THIS_DIR/build_util.sh


compress_output() {
	echo "Packaging build products"

	for bp in "${VALID_PLATFORMS[@]}" ; do
		for bc in "${VALID_CONFIGURATIONS[@]}" ; do

			TARGET_DIR=${APP_NAME}_${bp}_${bc}
			if [ -d $TARGET_DIR ]; then 
				echo "Packaging build product directory: $TARGET_DIR"
				if [ -n "$BUILD_SUFFIX" ]; then
					NEW_DIR=${TARGET_DIR}__${BUILD_SUFFIX}
					mv $TARGET_DIR $NEW_DIR
					TARGET_DIR=$NEW_DIR
				fi
				
				zip -qr ${TARGET_DIR}.zip ${TARGET_DIR}/
				
				if [ "$?" != "0" ]; then
				    echo "[Error] Failed compressing ${TARGET_DIR}!"
				    compression_error=true
				fi
				
				if [[ "$BUILD_Installer" == "true" && "$bp" == "MacOSX" ]]; then
					$BUILD_DIR/installer/MacOSX/assemble_installer.sh ${TARGET_DIR}
					if [ "$?" != "0" ]; then
						echo "[Error] building MacOSX installer for: ${TARGET_DIR}!"
						compression_error=true
					fi
				fi
		
			else
				echo "Ignoring missing build directory @: $TARGET_DIR"
			fi
		done
	done	

}

main() {
	pushd $OUTPUT_DIR
	report_error_and_exit "[Error] output directory does not exist!"
	
	compression_error=false

	compress_output

	if [ $compression_error = true ] ; then
		exit_error "[Error] Compression failed"
	  exit 1
	fi

	popd
	
	report_success
}

main
