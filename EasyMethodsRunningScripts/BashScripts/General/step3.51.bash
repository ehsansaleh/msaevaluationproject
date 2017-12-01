#!/bin/bash
#set -e

 
#This step Calculates the MAFFT alignment
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
outputdir=../../ProcessedData/ContralignAlignments/"$NucleicOrAmino"Acids/$DatasetName

mkdir -p $outputdir

cd $inputdir
inputdir=$(pwd)
cd - > /dev/null 2>&1

cd $outputdir
outputdir=$(pwd)
cd - > /dev/null 2>&1

topology=double_affine
if [ $DatasetName = "Homstrad" ];then
	mytopology=$CONTRALIGN_DIR/topologies/contralign.topology.$topology
	myparams=$CONTRALIGN_DIR/parameters/contralign.params.$topology.no_homstrad
elif [ $DatasetName = "MattBench" ];then
        mytopology=$CONTRALIGN_DIR/topologies/contralign.topology.$topology
        myparams=$CONTRALIGN_DIR/parameters/contralign.params.$topology.no_sabmark165
elif [ $DatasetName = "BAliBase" ];then
        mytopology=$CONTRALIGN_DIR/topologies/contralign.topology.$topology
        myparams=$CONTRALIGN_DIR/parameters/contralign.params.$topology.no_bali3
else
	mytopology=$CONTRALIGN_DIR/contralign.topology
        myparams=$CONTRALIGN_DIR/contralign.params
fi

echo Doing ContraAlign Alignment on Raw Fasta Files ...
cd $inputdir
echo $inputdir
for file in *; do
	if [[ ! -s $outputdir/$file ]]; then
		filename=${file%.*}
		extension=${file##*.}
		contralign --topology $mytopology --params $myparams -v $file > $outputdir/$file
	fi
done
