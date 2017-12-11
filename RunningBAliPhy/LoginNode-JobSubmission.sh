#!/bin/bash

#Warning: This script removes the old config files and log files once it runs.
#In other words, running the submission script twice would destroy the last run's configurations.
#You can create a backup of this whole folder in case you'd like to.

NucleicOrAmino=Amino
DatasetName=BAliBase

#Since one needs to run multiple independent runs of BAliPhy for each set of sequences, and the number of available processors might exceed the number of independent runs for each set of sequences,...
#...this script provides a platform for using the full extent of a processor's power for running BAliPhy multiple times on multiple sets of sequences.
procpercore=32
bpinstance=32
#if procpercore=30 and bpinstance=6, then 5 batch(each with 6 independent runs) of bp will run on a single node.
faspercore=$((procpercore/bpinstance))

#The address for the executable of bali-phy and its bin folder
bp=/mnt/b/projects/sciteam/badu/ehsan/programs/bali-phy/bin/bali-phy
bpadr=/mnt/b/projects/sciteam/badu/ehsan/programs/bali-phy/bin

#Declaring the input folder
infolder=input/"$NucleicOrAmino"Acids/$DatasetName
outfolder=/scratch/sciteam/saleh1/BPOutput/BPRunnings/"$NucleicOrAmino"Acids/$DatasetName
bpanalysisscriptfolder=../AnalyzeBP/paralbpanalyze/

#Creating New Output Folder
mkdir -p $outfolder

#Converting relative path variable to absolute path variables
cd $infolder
infolder=$(pwd)
cd - > /dev/null 2>&1

cd $bpanalysisscriptfolder
bpanalysisscriptfolder=$(pwd)
cd - > /dev/null 2>&1

#Creating new analysis folders
analysisfolder=$bpanalysisscriptfolder/output/"$NucleicOrAmino"Acids/$DatasetName
if [ ! -d $analysisfolder ]; then
  mkdir $analysisfolder
fi

#Warning: This script removes the old config files and log files once it runs.
#In other words, running the submission script twice would destroy the last run's configurations.
#You can create a backup of this whole folder in case you'd like to.
rm -rf ./config/
mkdir config

rm -rf logs/
mkdir logs/

#The csv file with the information necessary for running the files
csvfile=$infolder/*.csv
rm -rf $outfolder
mkdir $outfolder
echo $csvfile
linenumber=0
confignum=1
intcfgcount=0
jobname=BPRun-$DatasetName

#Iterating through the datasets being read from the csv file, and creating the necessary configuration files
while IFS= read line
do
	((linenumber++))
	if [ $linenumber \> 1 ];
	then
		fastaname=${line%%,*}
		#Just Removing the extension, and extracting the fastaname
		extension=${fastaname##*.}
		fastaname=${fastaname%.*}
		line=${line#*,}
		dtype=${line%%,*}
                line=${line#*,}
		raxmlmodel=${line%%,*}
                line=${line#*,}
		bpmodel=${line%%,*}
		bpmodel=$(echo $bpmodel | sed 's/[^a-zA-Z0-9]//g')
                line=${line#*,}
		#Printing the properties of this dataset
		echo "File Name: "$fastaname
		echo "Data Type is "$dtype
		echo "RAxML Evolution Model: "$raxmlmodel
		echo "BaliPhy Evolution Model: "$bpmodel
		echo "--"
		inputaddress=$infolder/$fastaname".$extension"
		oldruns=$(ls *$inputaddress* 2> /dev/null)
		rm -rf $oldruns
		#Adding the necessary configuration lines to the related config file for each independent run of BaliPhy on each dataset.
		#Hint: There will be $procpercore lines in each configuration files, relating to $procpercore different processes on each core.
		for (( c=1; c<=bpinstance; c++ ))
		do
			echo -n $bpadr":" >> ./config/config-$confignum.txt
			echo -n $inputaddress":" >> ./config/config-$confignum.txt
			echo -n $fastaname":" >> ./config/config-$confignum.txt
			echo -n $dtype":" >> ./config/config-$confignum.txt
			echo -n $bpmodel":" >> ./config/config-$confignum.txt
			echo -n $outfolder":" >> ./config/config-$confignum.txt
			echo $c":" >> ./config/config-$confignum.txt
		done
		intcfgcount=$((intcfgcount+1))
		subjobname=$jobname-$fastaname
		
		if [ $intcfgcount -ge $faspercore ]
		then
			#Submitting the job
			qsub runbp.pbs -N $subjobname -v cfgadr="./config/config-$confignum.txt"
			
			echo "Baliphy Running Job "$confignum" was submitted."
			
			tempadreess=$(pwd)
			cd $bpanalysisscriptfolder
			qsub datasetsubmitter.pbs -W depend=afterany:$bprunjobid -N BPAnz-$DatasetName-$fastaname -v datasetname=$fastaname,outfolder=$analysisfolder,infolder=$outfolder
			cd $tempadreess
			
			echo "BPAnalyze Job "$confignum" was submitted too."
			echo "----------"
			intcfgcount=0
			confignum=$((confignum+1))
		fi
	fi;
done < $csvfile
