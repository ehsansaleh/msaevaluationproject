#!/bin/bash
###PBS -W depend=afterany:<JobID>
set -e
#This step Finds the best evolutionary model for proteins for statalign, and creates a csv file for it

#Warning this script removes any existing output directory
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
	NucleicOrAmino=Amino
	#Or set it to NucleicOrAmino=Amino if you need AA datasets
	DatasetName=BAliBase
	dtype=Amino-Acids
	#dtype should be either of these three "Amino-Acids" "RNA" "DNA"
else
	NucleicOrAmino=$1
	DatasetName=$2
	dtype=$3
fi

inputdir=../../ProcessedData/LINSIAlignments/"$NucleicOrAmino"Acids/$DatasetName
csvfile=../../ProcessedData/AlphabetAndModel/"$NucleicOrAmino"Acids/$DatasetName-StatAlign.csv

protmodelscript=$(pwd)/AICProtModel.py

#Converting the relative address of the csvfile to an absolute path
csvadress="${csvfile%/*}"
cd $csvadress
csvadress=$(pwd)
cd - > /dev/null 2>&1
csvfile=$csvadress/$DatasetName-StatAlign.csv

function nameconverter()
{
	local inputraxmlmodel=$1
	local outval=""
	if [[ $inputraxmlmodel == "BLOSUM62" ]];then
		outval="Blosum"
	elif [[ $inputraxmlmodel == "CPREV" ]];then
		outval="CpRev"
	elif [[ $inputraxmlmodel == "DAYHOFF" ]];then
		outval="Dayhoff"
	elif [[ $inputraxmlmodel == "JTT" ]];then
		outval="Jones"
	elif [[ $inputraxmlmodel == "MTMAM" ]];then
		outval="MtMam"
	elif [[ $inputraxmlmodel == "MTREV" ]];then
		outval="MtREV"
	elif [[ $inputraxmlmodel == "RTREV" ]];then
		outval="RtREV"
	elif [[ $inputraxmlmodel == "VT" ]];then
		outval="Vt"
	elif [[ $inputraxmlmodel == "WAG" ]];then
		outval="Wag"
	elif [[ $inputraxmlmodel == "tempmodel" ]];then
		outval="tempmodel"
	fi
	echo $outval
}

#Converting the relative address of the pythonscript to an absolute path
pyadress="${protmodelscript%/*}"
pyfilename="${protmodelscript##*/}"
cd $pyadress
pyadress=$(pwd)
cd - > /dev/null 2>&1
protmodelscript=$pyadress/$pyfilename

#Internal Options for running RAxML Fast on the amino acid datasets
ProcNumber=12
tempfolder=mysatemp
currfolder=$(pwd)



cd $inputdir
inputdir=$(pwd)
cd - > /dev/null 2>&1

echo Creating The CSV file with the evolutionary models
echo "File Name, Data Type, StatAlign Model" > $csvfile
if [ $NucleicOrAmino == Nucleic ]; then
	samodel=ReversibleNucleotide
	for file in $inputdir/*.fna; do
		filename=$(basename $file)
		echo $filename,$dtype,$samodel
		echo $filename,$dtype,$samodel >> $csvfile
	done
else
	
	rm -rf $tempfolder
	mkdir $tempfolder
	cd $tempfolder
	tempfolder=$(pwd)
	for ((x = 0 ; x < $ProcNumber ; x++)); do
		mkdir temp$x
	done
	
	i=0
	validmodels=""
	for file in $inputdir/*.faa; do
		filename=$(basename $file)
		echo $filename
		cd $tempfolder/temp$i
		rm -rf *
		mkdir gentemp
		mkdir bptemp
		echo $filename > filename.txt
		
		#Running RAxML model selection python script on all alignments of a benchmark.
		#This step is done in parallel and generates background processes.
		#If you just want to use LG for datasets with less than 4 sequences, jus remove the if, and keep the else part (i.e. run python $protmodelscript on every dataset).
		if [[ $(grep ">" < $file | wc -l) -lt 4 ]]; then
		
			echo tempmodel > SAModel.txt
			
		else
			
			cd bptemp
			python $protmodelscript -i $file -m BLOSUM62:CPREV:DAYHOFF:JTT:MTMAM:MTREV:RTREV:VT:WAG -c aic -r raxml > ../SAModel.txt &
			cd ..
		fi
		
		
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
				samodel=$(cat $tempfolder/temp$x/SAModel.txt)
				samodel=$(nameconverter $samodel)
				if [[ ! $samodel  = "tempmodel" ]]; then
					validmodels=$validmodels,$samodel
				fi
				echo $myfilename,$dtype,$samodel
				echo $myfilename,$dtype,$samodel >> $csvfile
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
				myfilename=$(cat $tempfolder/temp$x/filename.txt)
				samodel=$(cat $tempfolder/temp$x/SAModel.txt)
				samodel=$(nameconverter $samodel)
				echo $myfilename,$dtype,$samodel
				echo $myfilename,$dtype,$samodel >> $csvfile
			done
			i=0
		fi
	
	if [[ $validmodels = "" ]]; then
		validmodels=Dayhoff
	fi
	popularmodel=$(echo $validmodels | tr , "\n" | sort | uniq -c | sort -r | head -1|  xargs | cut -d" " -f2-)
	sed -i "s|tempmodel|$popularmodel|g" $csvfile
	rm -rf $tempfolder
fi
