#!/bin/bash
#set -e

 
#This step Calculates the ContrAlign alignment
#Warning this script removes any existing output directory
if [ -z "$1" ] || [ -z "$2" ]; then
	NucleicOrAmino=Amino
	#Or set it to NucleicOrAmino=Amino if you need AA datasets
	DatasetName=BAliBase
else
	NucleicOrAmino=$1
	DatasetName=$2
fi

inputdir=../../Datasets/SampledAndRenamedAndUnaligned/"$NucleicOrAmino"Acids/$DatasetName
#outputdir=../../ProcessedData/ContralignDefaulAlignments/"$NucleicOrAmino"Acids/$DatasetName
outputdir=../../ProcessedData/ContralignV104DefaulAlignments/"$NucleicOrAmino"Acids/$DatasetName

mkdir -p $outputdir

cd $inputdir
inputdir=$(pwd)
cd - > /dev/null 2>&1

cd $outputdir
outputdir=$(pwd)
cd - > /dev/null 2>&1

#mytopology=$CONTRALIGN_DIR/contralign.topology
myparams=$CONTRALIGN_DIR/contralign.params


echo Doing ContraAlign Alignment on Raw Fasta Files ...
cd $inputdir
echo $inputdir
for file in *; do
	if [[ ! -s $outputdir/$file ]]; then
		filename=${file%.*}
		extension=${file##*.}
		#echo contralign --topology $mytopology --params $myparams -v $file > $outputdir/$file
		contralign --params $myparams -v $file > $outputdir/$file
		#contralign predict --params $CONTRALIGN_DIR/contralign.params.protein $file --mfa $outputdir/$file
		#contralign predict $file --mfa $outputdir/$file
	fi
done
