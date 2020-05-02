#!/bin/zsh
set -eu

if [[ $# -ne 2 ]]; then
	echo "Usage: $0 <input file (python)> <output directory>"
	echo "See the examples folder for the example input files"
	echo "input file should be in the form of a python input,"
	echo "so examples/sort.py should be examples.sort"
	exit 1
fi

inputfile=$1
outputdir=$2

mkdir -p $outputdir
python3 generate_examples.py $inputfile $outputdir

synthesis_files=( $(find $outputdir -name '*.json') )

echo "Synthesis examples generated! Starting the synthesizer!"
echo "Synthesizing ${#synthesis_files} files"
parallel ./_build/default/bin/l2_cli.exe synth {} '>' {}.synth_output ::: ${synthesis_files[@]}
