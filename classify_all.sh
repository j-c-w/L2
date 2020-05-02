#!/bin/bash

if [[ $# -lt 2 ]]; then
	echo "Usage: $0 <output directory> <tests to run....>"
	exit 1
fi

output=$1
shift

while [[ $# -gt 0 ]]; do
	input=$1
	shift

	# Need to keep each output folder unique wrt. each input folder.
	./classify.sh $input ${output}${input}
done
