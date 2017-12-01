#!/bin/bash
###PBS -W depend=afterany:<JobID>
if [ ! -z $PBS_O_WORKDIR ]; then cd $PBS_O_WORKDIR; fi;
#This step Finds the best evolutionary model for proteins, and creates a csv file for it

#Warning this script removes any existing output directory
if [ -z "$1" ] || [ -z "$2" ]; then
	NucleicOrAmino=Nucleic
	#Or set it to NucleicOrAmino=Amino if you need AA datasets
	DatasetName=BRaliBase
else
	NucleicOrAmino=$1
	DatasetName=$2
fi

inputdir=../../Datasets/SampledAndRenamed/"$NucleicOrAmino"Acids/$DatasetName
outputdir=../../ProcessedData/RAxMLTrees/"$NucleicOrAmino"Acids/Reference/$DatasetName

#Internal Options for running RAxML Fast on the amino acid datasets
ProcNumber=16
tempfolder=raxmltemp
currfolder=$(pwd)

cd $inputdir
inputdir=$(pwd)
cd - > /dev/null 2>&1

rm -rf $outputdir
mkdir $outputdir
cd $outputdir
outputdir=$(pwd)
cd - > /dev/null 2>&1

echo Computing the raxml trees on the reference alignment
if [ $NucleicOrAmino == Nucleic ]; then
	evolmodel=GTRGAMMAI
	extension=fna
else
	evolmodel=PROTGAMMAIAUTO
	extension=faa
fi


rm -rf $tempfolder
mkdir $tempfolder
cd $tempfolder
tempfolder=$(pwd)
for ((x = 0 ; x < $ProcNumber ; x++)); do
	mkdir temp$x
done

i=0

echo $inputdir
for file in $inputdir/*.$extension; do
	filename=$(basename $file)
	smallname="${filename%.*}"
	echo $filename
	cd $tempfolder/temp$i
	rm -rf *
	#autoMRE
	raxml -s $file -n $smallname -m $evolmodel -f a -p 34567 -x 34567 -N autoMRE --auto-prot=aic > raxlog.txt &
	
	i=$((i+1))
	
	if [ $i -ge $ProcNumber ]; then
		i=0
		echo -n Start Time:
		date +"%T"
		wait
		echo -n End Time:
		date +"%T"
		for ((x = 0 ; x < $ProcNumber ; x++)); do
			besttreeaddress=$(echo $tempfolder/temp$x/RAxML_bestTree.*)
			bootstraptreeaddress=$(echo $tempfolder/temp$x/RAxML_bipartitionsBranchLabels.*)
			smallname=${besttreeaddress##*/}
			smallname=${smallname#*.}
			mv $besttreeaddress $outputdir/$smallname"_MLParams".nwk
			mv $bootstraptreeaddress $outputdir/$smallname"_MLbootstrap".nwk
		done
	fi
done

if [ $i -gt 0 ]; then
		echo -n Start Time:
		date +"%T"
		wait
		echo -n End Time:
		date +"%T"
		for ((x = 0 ; x < $i ; x++)); do
			besttreeaddress=$(echo $tempfolder/temp$x/RAxML_bestTree.*)
			bootstraptreeaddress=$(echo $tempfolder/temp$x/RAxML_bipartitionsBranchLabels.*)
			smallname=${besttreeaddress##*/}
			smallname=${smallname#*.}
			mv $besttreeaddress $outputdir/$smallname"_MLParams".nwk
			mv $bootstraptreeaddress $outputdir/$smallname"_MLbootstrap".nwk
		done
		i=0
	fi

rm -rf $tempfolder
