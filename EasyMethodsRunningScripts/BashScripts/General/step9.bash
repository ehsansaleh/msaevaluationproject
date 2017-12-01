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

cd $bpanalysisfolder
bpanalysisfolder=$(pwd)
cd - > /dev/null 2>&1

mkdir -p $DatasetName

python $essscript -i $bpanalysisfolder -o $DatasetName/$DatasetName"ESS".csv

