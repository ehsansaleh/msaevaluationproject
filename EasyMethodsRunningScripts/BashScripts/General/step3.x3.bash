#!/bin/bash
#set -e

 
unset MAFFT_BINARIES
#This step Calculates the Prime alignment
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
	NucleicOrAmino=Amino
	#Or set it to NucleicOrAmino=Amino if you need AA datasets
	DatasetName=BAliBase
	allnodes=20
else
	NucleicOrAmino=$1
	DatasetName=$2
	allnodes=$3
fi

inputdir=../../Datasets/SampledAndRenamedAndUnaligned/"$NucleicOrAmino"Acids/$DatasetName
outputdir=../../ProcessedData/PromalsFiles/"$NucleicOrAmino"Acids/$DatasetName
maxjobs=14

arrid=$PBS_ARRAYID

mkdir -p $outputdir

cd $inputdir
inputdir=$(pwd)
cd - > /dev/null 2>&1

cd $outputdir
outputdir=$(pwd)
cd - > /dev/null 2>&1


echo Doing Promals Alignment on Raw Fasta Files ...
#Generating a list of TODO alignment tasks for ourselves.
cd $inputdir
echo $inputdir
inputfilesarray=()
outputfilesarray=()
alljobs=0
counter=0
for file in *; do
	if [ $counter -eq $arrid ]; then
		filename=${file%.*}
		extension=${file##*.}
	
		inputfilesarray+=($inputdir/$file)
		outputfilesarray+=($outputdir/$filename)
		alljobs=$((alljobs+1))
	fi
	counter=$((counter+1))
	if [ $counter -ge $allnodes ];then
		counter=0
	fi
done

currentjob=0
while [[ $currentjob -lt $alljobs ]]; do
        if [[ $(jobs -r | wc -l) -lt $maxjobs ]];then
                #Here you shoud create your new job
		oldloc=$(pwd)

		origfasta=${inputfilesarray[$currentjob]}
		myfastaname=${origfasta##*/}
		myfasta=${myfastaname%.*}
		if [ ! -s ${outputfilesarray[$currentjob]}/$myfasta.faa.promals.aln ]; then
			rm -rf ${outputfilesarray[$currentjob]}
			mkdir -p ${outputfilesarray[$currentjob]}
			cd ${outputfilesarray[$currentjob]}
			cp $origfasta $myfastaname
			python /projects/tallis/ehsan/promals/promals_package/bin/promals $myfastaname -dali 0 -tmalign 0 -fast 0 > $myfastaname.NodeLog &
		fi
		cd $oldloc

                #Updating the flag for next job
                currentjob=$((currentjob+1))
        else
	        #sleep untill next poll
	        sleep 1
        fi
done

#Waiting for the last batch to finish
wait
