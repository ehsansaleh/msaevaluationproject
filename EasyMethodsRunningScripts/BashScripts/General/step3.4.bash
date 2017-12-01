#!/bin/bash
#set -e

 
#This step Calculates the PRANK alignment
if [ -z "$1" ] || [ -z "$2" ]; then
	NucleicOrAmino=Amino
	#Or set it to NucleicOrAmino=Amino if you need AA datasets
	DatasetName=BAliBase
else
	NucleicOrAmino=$1
	DatasetName=$2
fi

inputdir=../../Datasets/SampledAndRenamedAndUnaligned/"$NucleicOrAmino"Acids/$DatasetName
outputdir=../../ProcessedData/PrankAlignments/"$NucleicOrAmino"Acids/$DatasetName

mkdir -p $outputdir

cd $inputdir
inputdir=$(pwd)
cd - > /dev/null 2>&1

cd $outputdir
outputdir=$(pwd)
cd - > /dev/null 2>&1


echo Doing Prank Alignment on Raw Fasta Files ...
cd $inputdir
echo $inputdir
for file in *; do
	filename=${file%.*}
	extension=${file##*.}
	if [ ! -s $outputdir/$filename.$extension ];then
		/projects/tallis/ehsan/prank/prank -d=$file -o=$outputdir/$filename
		mv $outputdir/$filename.best.fas $outputdir/$filename.$extension
	fi
done
