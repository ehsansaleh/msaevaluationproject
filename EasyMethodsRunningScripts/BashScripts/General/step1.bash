#!/bin/bash

#This step just renames the sequences inside the datasets
#Warning this script removes any existing output directory

if [ -z "$1" ] || [ -z "$2" ]; then
	NucleicOrAmino=Amino
	#Or set it to NucleicOrAmino=Amino if you need AA datasets
	DatasetName=MattBench
else
	NucleicOrAmino=$1
	DatasetName=$2
fi

inputdir=../../Datasets/Sampled/"$NucleicOrAmino"Acids/$DatasetName
outputdir=../../Datasets/SampledAndRenamed/"$NucleicOrAmino"Acids/$DatasetName

#if [ -d $outputdir ]; then
#	rm -rf $outputdir
#fi
mkdir -p $outputdir

cd $inputdir
inputdir=$(pwd)
cd - > /dev/null 2>&1

cd $outputdir
outputdir=$(pwd)
cd - > /dev/null 2>&1

echo Input Directory "==>" $inputdir
echo Output Directory "==>" $outputdir

python StrangeToSimpleNamemapper.py -r -i $inputdir -o $outputdir
