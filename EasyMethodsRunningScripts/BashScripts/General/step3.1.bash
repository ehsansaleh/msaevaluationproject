#!/bin/bash
#set -e

 
#This step Calculates the Muscle alignment

#Warning this script removes any existing output directory
if [ -z "$1" ] || [ -z "$2" ]; then
	NucleicOrAmino=Nucleic
	#Or set it to NucleicOrAmino=Amino if you need AA datasets
	DatasetName=BRaliBase
else
	NucleicOrAmino=$1
	DatasetName=$2
fi

inputdir=../../Datasets/SampledAndRenamedAndUnaligned/"$NucleicOrAmino"Acids/$DatasetName
outputdir=../../ProcessedData/MuscleAlignments/"$NucleicOrAmino"Acids/$DatasetName

mkdir -p $outputdir

cd $inputdir
inputdir=$(pwd)
cd - > /dev/null 2>&1

cd $outputdir
outputdir=$(pwd)
cd - > /dev/null 2>&1

echo Doing Muscle Alignment on Raw Fasta Files ...
cd $inputdir
echo $inputdir
for file in *; do
	if [[ ! -s $outputdir/$file ]]; then
		muscle -in $file -out $outputdir/$file
	fi
done
