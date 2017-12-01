#!/bin/bash
#set -e

 
#This step Calculates the ProbCons alignment
if [ -z "$1" ] || [ -z "$2" ]; then
	NucleicOrAmino=Amino
	#Or set it to NucleicOrAmino=Amino if you need AA datasets
	DatasetName=BAliBase
else
	NucleicOrAmino=$1
	DatasetName=$2
fi

inputdir=../../Datasets/SampledAndRenamedAndUnaligned/"$NucleicOrAmino"Acids/$DatasetName
outputdir=../../ProcessedData/DefaultProbConsAlignments/"$NucleicOrAmino"Acids/$DatasetName
maxjobs=12

mkdir -p $outputdir

cd $inputdir
inputdir=$(pwd)
cd - > /dev/null 2>&1

cd $outputdir
outputdir=$(pwd)
cd - > /dev/null 2>&1


echo Doing Default ProbCons Alignment on Raw Fasta Files ...
cd $inputdir
echo $inputdir
inputfilesarray=()
outputfilesarray=()
alljobs=0
for file in *; do
	filename=${file%.*}
	extension=${file##*.}
	
	inputfilesarray+=($inputdir/$file)
	outputfilesarray+=($outputdir/$filename.$extension)
	alljobs=$((alljobs+1))
done

currentjob=0
while [[ $currentjob -lt $alljobs ]]; do
        if [[ $(jobs -r | wc -l) -lt $maxjobs ]];then
                #Here you shoud create your new job
		if [[ ! -s ${outputfilesarray[$currentjob]} ]];then
			probcons ${inputfilesarray[$currentjob]} > ${outputfilesarray[$currentjob]} &
		fi

                #Updating the flag for next job
                currentjob=$((currentjob+1))
        else
	        #sleep untill next poll
	        sleep 1
        fi
done

#Waiting for the last batch to finish
wait
