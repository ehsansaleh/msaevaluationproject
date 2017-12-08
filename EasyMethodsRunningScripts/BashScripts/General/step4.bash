#!/bin/bash
#This step Finds the best evolutionary model for proteins for BaliPhy, and creates a csv file for it

#Warning this script removes any existing output directory
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
	NucleicOrAmino=Amino
	#Or set it to NucleicOrAmino=Amino if you need AA datasets
	DatasetName=SubSampled
	dtype=Amino-Acids
	#dtype should be either of these three "Amino-Acids" "RNA" "DNA"
else
	NucleicOrAmino=$1
	DatasetName=$2
	dtype=$3
fi

inputdir=../../ProcessedData/LINSIAlignments/"$NucleicOrAmino"Acids/$DatasetName
csvfile=../../ProcessedData/AlphabetAndModel/"$NucleicOrAmino"Acids/$DatasetName.csv

protmodelscript=$(pwd)/AICProtModel.py

#Converting the relative address of the csvfile to an absolute path
csvadress="${csvfile%/*}"
cd $csvadress
csvadress=$(pwd)
cd - > /dev/null 2>&1
csvfile=$csvadress/$DatasetName.csv

#Converting the relative address of the pythonscript to an absolute path
pyadress="${protmodelscript%/*}"
pyfilename="${protmodelscript##*/}"
cd $pyadress
pyadress=$(pwd)
cd - > /dev/null 2>&1
protmodelscript=$pyadress/$pyfilename

#Internal Options for running RAxML Fast on the amino acid datasets
ProcNumber=16
tempfolder=mybptemp
currfolder=$(pwd)



cd $inputdir
inputdir=$(pwd)
cd - > /dev/null 2>&1

echo Creating The CSV file with the evolutionary models
echo "File Name, Data Type, RAxML Model, Baliphy Model" > $csvfile
if [ $NucleicOrAmino == Nucleic ]; then
	#In case the alignments are nucleotides, we'll just have to output GTRGAMMAI
	raxmodel=GTRGAMMAI
	bpmodel=GTR
	for file in $inputdir/*.fna; do
		filename=$(basename $file)
		echo $filename,$dtype,$raxmodel,$bpmodel
		echo $filename,$dtype,$raxmodel,$bpmodel >> $csvfile
	done
else
	#For protein alignments, we have to do the following
	
	rm -rf $tempfolder
	mkdir $tempfolder
	cd $tempfolder
	tempfolder=$(pwd)
	for ((x = 0 ; x < $ProcNumber ; x++)); do
		mkdir temp$x
	done
	
	i=0
	
	#Running RAxML model selection python script on all alignments of a benchmark two times.
	#One time, we'll select among models supported by BaliPhy.
	#The other time, we'll select among all known models.
	#This step is done in parallel and generates background processes.
	for file in $inputdir/*.faa; do
		filename=$(basename $file)
		echo $filename
		cd $tempfolder/temp$i
		rm -rf *
		mkdir gentemp
		mkdir bptemp
		echo $filename > filename.txt
		
		#sleep 4 &
		cd gentemp
		python $protmodelscript -i $file -m All -c aic -r raxml > ../RAxMLModel.txt &
		#echo Rax$filename > ../RAxMLModel.txt &
		cd ..
		
		cd bptemp
		python $protmodelscript -i $file -m JTT:WAG:LG -c aic -r raxml > ../BPModel.txt &
		#echo BP$filename > ../BPModel.txt &
		cd ..
		
		i=$((i+1))
		
		if [ $i -ge $ProcNumber ]; then
			i=0
			echo -n Start Time:
			date +"%T"
			wait
			echo -n End Time:
			date +"%T"
			for ((x = 0 ; x < $ProcNumber ; x++)); do
				myfilename=$(cat $tempfolder/temp$x/filename.txt)
				bpmodel=$(cat $tempfolder/temp$x/BPModel.txt)
				raxmodel=$(cat $tempfolder/temp$x/RAxMLModel.txt)
				echo $myfilename,$dtype,$raxmodel,$bpmodel
				echo $myfilename,$dtype,$raxmodel,$bpmodel >> $csvfile
			done
		fi
		#raxmodel=$(python $protmodelscript -i $file -m All -c aic -r raxml)
		#bpmodel=$(python $protmodelscript -i $file -m JTT:WAG:LG -c aic -r raxml)
	done
	
	if [ $i -gt 0 ]; then
			echo -n Start Time:
			date +"%T"
			wait
			echo -n End Time:
			date +"%T"
			for ((x = 0 ; x < $i ; x++)); do
				myfilename=$(cat $tempfolder/temp$x/filename.txt)
				bpmodel=$(cat $tempfolder/temp$x/BPModel.txt)
				raxmodel=$(cat $tempfolder/temp$x/RAxMLModel.txt)
				echo $myfilename,$dtype,$raxmodel,$bpmodel
				echo $myfilename,$dtype,$raxmodel,$bpmodel >> $csvfile
			done
			i=0
		fi
	
	rm -rf $tempfolder
fi
