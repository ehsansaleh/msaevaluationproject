#!/bin/bash
#set -e

 
#This step Calculates the Prime alignment
if [ -z "$1" ] || [ -z "$2" ]; then
	NucleicOrAmino=Amino
	#Or set it to NucleicOrAmino=Amino if you need AA datasets
	DatasetName=BAliBase
else
	NucleicOrAmino=$1
	DatasetName=$2
fi

inputdir=../../Datasets/SampledAndRenamedAndUnaligned/"$NucleicOrAmino"Acids/$DatasetName
outputdir=../../ProcessedData/PrimeAlignments/"$NucleicOrAmino"Acids/$DatasetName

mkdir -p $outputdir

cd $inputdir
inputdir=$(pwd)
cd - > /dev/null 2>&1

cd $outputdir
outputdir=$(pwd)
cd - > /dev/null 2>&1


echo Doing Prime Alignment on Raw Fasta Files ...
cd $inputdir
echo $inputdir
for file in *; do
	filename=${file%.*}
	extension=${file##*.}
	if [ ! -s $outputdir/$filename.$extension ];then
		cd /projects/tallis/ehsan/prime/
		if [[ $filename == *RNA* ]];then
			prime -t rna -i $inputdir/$file -o $outputdir/$filename.$extension
		else
			prime -i $inputdir/$file -o $outputdir/$filename.$extension
		fi
		cd -
	fi
done
