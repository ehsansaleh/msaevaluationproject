#!/bin/bash
#set -e

 
#This step Calculates the Pagan alignment
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
outputdir=../../ProcessedData/PaganAlignments/"$NucleicOrAmino"Acids/$DatasetName
treeoutdir=../../ProcessedData/PaganTrees/"$NucleicOrAmino"Acids/$DatasetName

mkdir -p $outputdir

mkdir -p $treeoutdir

cd $inputdir
inputdir=$(pwd)
cd - > /dev/null 2>&1

cd $outputdir
outputdir=$(pwd)
cd - > /dev/null 2>&1

cd $treeoutdir
treeoutdir=$(pwd)
cd - > /dev/null 2>&1

echo Doing Pagan Alignment on Raw Fasta Files ...
cd $inputdir
echo $inputdir
for file in *; do
	if [[ ! -s $outputdir/$file ]]; then
		filename=${file%.*}
		extension=${file##*.}
		#You have to make sure that pagan is running correctly, and uses the right mafft before running it. This needs to be verified by the end-user.
		pagan -s $file -o $outputdir/$filename --threads 12
		mv $outputdir/$filename.fas $outputdir/$filename.$extension
		mv $outputdir/$filename.tre $treeoutdir/$filename.nwk
		rm warnings
	fi
done
