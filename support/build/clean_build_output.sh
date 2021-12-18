#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $THIS_DIR/build_util.sh


rm -rf $OUTPUT_DIR
report_error_and_exit "Failed cleaning up output directory"

rm -f $BASE_DIR/*.log
report_error_and_exit "Failed cleaning up build logs"

mkdir -p $OUTPUT_DIR
report_error_and_exit "Failed creating output directory"

report_success
