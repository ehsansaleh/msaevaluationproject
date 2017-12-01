#!/bin/bash
#set -e

 
#This step Calculates the K-Align alignment
if [ -z "$1" ] || [ -z "$2" ]; then
	NucleicOrAmino=Amino
	#Or set it to NucleicOrAmino=Amino if you need AA datasets
	DatasetName=BAliBase
else
	NucleicOrAmino=$1
	DatasetName=$2
fi

inputdir=../../Datasets/SampledAndRenamedAndUnaligned/"$NucleicOrAmino"Acids/$DatasetName
outputdir=../../ProcessedData/KAlignAlignments/"$NucleicOrAmino"Acids/$DatasetName

mkdir -p $outputdir

cd $inputdir
inputdir=$(pwd)
cd - > /dev/null 2>&1

cd $outputdir
outputdir=$(pwd)
cd - > /dev/null 2>&1


echo Doing K-Align Alignment on Raw Fasta Files ...
cd $inputdir
echo $inputdir
for file in *; do
	filename=${file%.*}
	extension=${file##*.}
	if [ ! -s $outputdir/$filename.$extension ];then
		kalign $file $outputdir/$filename.$extension
	fi
done
