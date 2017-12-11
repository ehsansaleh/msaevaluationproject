#!/bin/bash

configaddress=$1

#This script reads the configurations from the input config file, and runs the process on the computational node
#First Arguemnt is baliphy full address
#Second Argument is the input fasta file full address
#Third Argument is the dataset name(ususally just simple fastaname)
#Fourth Argument is the data type(RNA, DNA or Amino Acids)
#Fifth Argument is the evolution model
#Sixth Argument is the output folder address

currentfolder=$(pwd)

while IFS=: read -r bpadress inadress fastaname datatype model outfolder instancenum
do
	cd $outfolder
	${bpadress}/bali-phy ${inadress} \
	-n ${fastaname}"-"${instancenum} \
	--alphabet ${datatype} \
	--smodel ${model}+F+gamma_inv[4] \
	--imodel RS07 \
	--randomize-alignment \
	--iterations=10000000 \
	--package-path=/mnt/b/projects/sciteam/badu/ehsan/programs/bali-phy/lib/bali-phy >> $currentfolder/logs/${fastaname}-${instancenum}.log 2>&1  &
done <"$configaddress"
wait

