#!/bin/bash
#set -e

 
#This step Calculates the MAFFT LINSI alignment

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
outputdir=../../ProcessedData/LINSIAlignments/"$NucleicOrAmino"Acids/$DatasetName

mkdir -p $outputdir

cd $inputdir
inputdir=$(pwd)
cd - > /dev/null 2>&1

cd $outputdir
outputdir=$(pwd)
cd - > /dev/null 2>&1

echo Doing Mafft LINSI  Alignment on Raw Fasta Files ...
cd $inputdir
echo $inputdir
for file in *; do
	if [[ ! -s $outputdir/$file ]]; then
		mafft --maxiterate 1000 --localpair --thread 4 $file > $outputdir/$file
	fi
done
