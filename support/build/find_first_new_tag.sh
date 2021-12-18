#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $THIS_DIR/build_util.sh


TAG_HISTORY_FILE_NAME="project_tags"
NEW_TAG_FILE_NAME="tag_to_build.prop"



TAG_HISTORY_FILE_PATH="$OUTPUT_DIR/$TAG_HISTORY_FILE_NAME"
NEW_TAG_FILE_PATH="$OUTPUT_DIR/$NEW_TAG_FILE_NAME"


main() {
	
#lower verbosity
	set +x

	mkdir -p $OUTPUT_DIR
	report_error_and_exit "Creating output directory failed failed"
	
	rm -f "$NEW_TAG_FILE_NAME"
	
	
	git fetch --all --tags
	report_error_and_exit "Fetching tags from git"
	
	RAW_SORTED_REFS=$( git for-each-ref --sort=taggerdate --format '%(refname)' refs/tags )
#	echo "RAW_SORTED_REFS: $RAW_SORTED_REFS"
	RAW_SORTED_TAGS=$( echo "$RAW_SORTED_REFS" | cut -c 11- )
#	echo "RAW_SORTED_TAGS: $RAW_SORTED_TAGS"
	TAGS=$( echo "$RAW_SORTED_TAGS" | grep -v "jenkins" | grep -E "[RI]C[0-9]+$" )
#	echo "TAGS: $TAGS"
	
	if [[ -f $TAG_HISTORY_FILE_PATH ]]; then
		
		HISTORY_TAGS=$(cat $TAG_HISTORY_FILE_PATH)
		
		for TAG in $TAGS ; do
			if [[ $HISTORY_TAGS =~ $TAG ]]; then
#				echo "Found existing tag: $TAG"
				:
			else
				echo "Found new tag: $TAG - appending it to history"
				echo "$TAG" >> $TAG_HISTORY_FILE_PATH
				export NEW_TAG=$TAG
				echo "TAG_TO_BUILD=$TAG" > $NEW_TAG_FILE_PATH
				report_success
			fi
		done

		echo "Found no new tags"

	else
		echo "Couldn't find tag history file @: $TAG_HISTORY_FILE_PATH"
		echo "Creating new file containing all current tags"
#		echo "$TAGS"
		echo "$TAGS" > $TAG_HISTORY_FILE_PATH
	fi


	exit_error "No new tags found"
}


main
