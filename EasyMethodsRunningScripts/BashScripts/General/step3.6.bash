#!/bin/bash
#set -e

 
#This step Calculates the Di-Align alignment
if [ -z "$1" ] || [ -z "$2" ]; then
	NucleicOrAmino=Amino
	#Or set it to NucleicOrAmino=Amino if you need AA datasets
	DatasetName=BAliBase
else
	NucleicOrAmino=$1
	DatasetName=$2
fi

inputdir=../../Datasets/SampledAndRenamedAndUnaligned/"$NucleicOrAmino"Acids/$DatasetName
outputdir=../../ProcessedData/DiAlignAlignments/"$NucleicOrAmino"Acids/$DatasetName

mkdir -p $outputdir

cd $inputdir
inputdir=$(pwd)
cd - > /dev/null 2>&1

cd $outputdir
outputdir=$(pwd)
cd - > /dev/null 2>&1


echo Doing Di-Align Alignment on Raw Fasta Files ...
cd $inputdir
echo $inputdir
for file in *; do
	filename=${file%.*}
	extension=${file##*.}
	if [ ! -s $outputdir/$filename.$extension ];then
		dialign2-2 -fn $outputdir/$filename -fa $file
		mv $outputdir/$filename.fa $outputdir/$filename.$extension
		rm $outputdir/$filename
	fi
done
