#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ]; then
        NucleicOrAmino=Amino
        #Or set it to NucleicOrAmino=Amino if you need AA datasets
        DatasetName=Sisyphus
else
        NucleicOrAmino=$1
        DatasetName=$2
fi

essscript=$(pwd)/ESSScript.py
bpanalysisfolder=../../../MafftVsBaliphy/ProcessedData/BPAnalyzeResults/"$NucleicOrAmino"Acids/$DatasetName

#Converting the relative path to an absolute path
cd $bpanalysisfolder
bpanalysisfolder=$(pwd)
cd - > /dev/null 2>&1

mkdir -p $DatasetName

#Just running the ESS python Script on baliphy results
python $essscript -i $bpanalysisfolder -o $DatasetName/$DatasetName"ESS".csv

