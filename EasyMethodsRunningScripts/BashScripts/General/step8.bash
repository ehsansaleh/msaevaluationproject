#!/bin/bash

#This step assesses the accuracy of alignments and generates a csv file
set -e
#Warning this script removes any existing output directory
if [ -z "$1" ] || [ -z "$2" ];
then
	NucleicOrAmino=Amino
	#Or set it to NucleicOrAmino=Amino if you need AA datasets
	DatasetName=Sisyphus
else
	NucleicOrAmino=$1
	DatasetName=$2
fi


 
#Different estimated alignment folders for assessment
refalndir=../../Datasets/SampledAndRenamed/"$NucleicOrAmino"Acids/$DatasetName
mafftalndir=../../ProcessedData/MAFFTAlignments/"$NucleicOrAmino"Acids/$DatasetName
ginsialndir=../../ProcessedData/GINSIAlignments/"$NucleicOrAmino"Acids/$DatasetName
einsialndir=../../ProcessedData/EINSIAlignments/"$NucleicOrAmino"Acids/$DatasetName
linsialndir=../../ProcessedData/LINSIAlignments/"$NucleicOrAmino"Acids/$DatasetName
paganalndir=../../ProcessedData/PaganAlignments/"$NucleicOrAmino"Acids/$DatasetName
prankalndir=../../ProcessedData/PrankAlignments/"$NucleicOrAmino"Acids/$DatasetName
musclealndir=../../ProcessedData/MuscleAlignments/"$NucleicOrAmino"Acids/$DatasetName
clustalalndir=../../ProcessedData/ClustalWAlignments/"$NucleicOrAmino"Acids/$DatasetName
dialnalndir=../../ProcessedData/DiAlignAlignments/"$NucleicOrAmino"Acids/$DatasetName
kalnalndir=../../ProcessedData/KAlignAlignments/"$NucleicOrAmino"Acids/$DatasetName
primealndir=../../ProcessedData/PrimeAlignments/"$NucleicOrAmino"Acids/$DatasetName
probalnalndir=../../ProcessedData/ProbAlignAlignments/"$NucleicOrAmino"Acids/$DatasetName
#defaultContralndir=../../ProcessedData/ContralignDefaulAlignments/"$NucleicOrAmino"Acids/$DatasetName
defaultContralndir=../../ProcessedData/ContralignV104DefaulAlignments/"$NucleicOrAmino"Acids/$DatasetName
probconsalndir=../../ProcessedData/ProbConsAlignments/"$NucleicOrAmino"Acids/$DatasetName
defaultProbconsalndir=../../ProcessedData/DefaultProbConsAlignments/"$NucleicOrAmino"Acids/$DatasetName
#contraalndir=../../ProcessedData/ContralignAlignments/"$NucleicOrAmino"Acids/$DatasetName
bppdalndir=../../ProcessedData/BPAlnsTrees/"$NucleicOrAmino"Acids/$DatasetName/Alignments/PD
sapdalndir=../../ProcessedData/StatAlignPDAlignments/"$NucleicOrAmino"Acids/$DatasetName
bpmapalndir=../../ProcessedData/BPAlnsTrees/"$NucleicOrAmino"Acids/$DatasetName/Alignments/MAP
samulpdalndir=../../ProcessedData/StatAlignMulPDAlignments/"$NucleicOrAmino"Acids/$DatasetName
sasumpdalndir=../../ProcessedData/StatAlignSumPDAlignments/"$NucleicOrAmino"Acids/$DatasetName
tcoffeealndir=../../ProcessedData/TCoffeeAlignments/"$NucleicOrAmino"Acids/$DatasetName
promalsalndir=../../ProcessedData/PromalsAlignments/"$NucleicOrAmino"Acids/$DatasetName
maffthomalndir=../../ProcessedData/MAFFTHomologsAlignments/"$NucleicOrAmino"Acids/$DatasetName
maffthomlargedbalndir=../../ProcessedData/MAFFTHomologsLargeDBAlignments/"$NucleicOrAmino"Acids/$DatasetName
pralinealndir=../../ProcessedData/PralineAlignments/"$NucleicOrAmino"Acids/$DatasetName

fastspscript=$(pwd)/FastSPMoreStat.py

#In case you don't like to update the csv accuracy result files, set the flag equal to zero. Otherwise, put it equal to one.
updatescript=$(pwd)/UpdateStats.py
updateflag=0

csvavgdatacalc=$(pwd)/NewManyCsvToOne.py

#Changing the relative paths to absolute paths, in order to avoid problems.

cd $pralinealndir
pralinealndir=$(pwd)
cd - > /dev/null 2>&1

cd $maffthomlargedbalndir
maffthomlargedbalndir=$(pwd)
cd - > /dev/null 2>&1

cd $maffthomalndir
maffthomalndir=$(pwd)
cd - > /dev/null 2>&1

cd $promalsalndir
promalsalndir=$(pwd)
cd - > /dev/null 2>&1

cd $tcoffeealndir
tcoffeealndir=$(pwd)
cd - > /dev/null 2>&1

cd $sasumpdalndir
sasumpdalndir=$(pwd)
cd - > /dev/null 2>&1

cd $samulpdalndir
samulpdalndir=$(pwd)
cd - > /dev/null 2>&1

cd $bpmapalndir
bpmapalndir=$(pwd)
cd - > /dev/null 2>&1

cd $sapdalndir
sapdalndir=$(pwd)
cd - > /dev/null 2>&1

cd $bppdalndir
bppdalndir=$(pwd)
cd - > /dev/null 2>&1

cd $defaultProbconsalndir
defaultProbconsalndir=$(pwd)
cd - > /dev/null 2>&1

cd $probconsalndir
probconsalndir=$(pwd)
cd - > /dev/null 2>&1

cd $refalndir
refalndir=$(pwd)
cd - > /dev/null 2>&1

cd $probalnalndir
probalnalndir=$(pwd)
cd - > /dev/null 2>&1

cd $primealndir
primealndir=$(pwd)
cd - > /dev/null 2>&1

cd $kalnalndir
kalnalndir=$(pwd)
cd - > /dev/null 2>&1

cd $dialnalndir
dialnalndir=$(pwd)
cd - > /dev/null 2>&1

cd $mafftalndir
mafftalndir=$(pwd)
cd - > /dev/null 2>&1

if [[ $NucleicOrAmino == Amino ]]; then
	#cd $contraalndir
	#contraalndir=$(pwd)
	#cd - > /dev/null 2>&1

	cd $defaultContralndir
	defaultContralndir=$(pwd)
	cd - > /dev/null 2>&1
fi

cd $ginsialndir
ginsialndir=$(pwd)
cd - > /dev/null 2>&1

cd $linsialndir
linsialndir=$(pwd)
cd - > /dev/null 2>&1

cd $einsialndir
einsialndir=$(pwd)
cd - > /dev/null 2>&1

cd $paganalndir
paganalndir=$(pwd)
cd - > /dev/null 2>&1

cd $prankalndir
prankalndir=$(pwd)
cd - > /dev/null 2>&1

cd $musclealndir
musclealndir=$(pwd)
cd - > /dev/null 2>&1

cd $clustalalndir
clustalalndir=$(pwd)
cd - > /dev/null 2>&1

cd $bpmapalndir
bpmapalndir=$(pwd)
cd - > /dev/null 2>&1

lpdistarr=( 0.0 )
hpdistarr=( 1.0 )
csvextarr=( "" )

mkdir -p $DatasetName
cd $DatasetName

rm -rf reftempfolder
mkdir reftempfolder

if [[ $NucleicOrAmino == Nucleic ]]; then
	extension=fna
else
	extension=faa
fi

#Defining the list of methods to compare in each case
if [[ $NucleicOrAmino == Amino ]]; then
	methodnames=( Praline MAFFT-H-LargeDB MAFFT-Homologs Promals TCoffee SAPDMul SAPDSum BPMAP SAPD BPPD MAFFT LINSI GINSI EINSI Prank Muscle Clustal DiAlign KAlign Prime ProbAlign DefaultContrAlign ProbCons DefaultProbCons )
	estalnfolders=( $pralinealndir $maffthomlargedbalndir $maffthomalndir $promalsalndir $tcoffeealndir $samulpdalndir $sasumpdalndir $bpmapalndir $sapdalndir $bppdalndir $mafftalndir $linsialndir $ginsialndir $einsialndir $prankalndir $musclealndir $clustalalndir $dialnalndir $kalnalndir $primealndir $probalnalndir $defaultContralndir $probconsalndir $defaultProbconsalndir )
else
	methodnames=( SAPDMul SAPDSum BPMAP SAPD BPPD MAFFT LINSI GINSI EINSI Muscle Clustal DiAlign KAlign Prime ProbAlign ProbCons DefaultProbCons )
	estalnfolders=( $samulpdalndir $sasumpdalndir $bpmapalndir $sapdalndir $bppdalndir $mafftalndir $linsialndir $ginsialndir $einsialndir $musclealndir $clustalalndir $dialnalndir $kalnalndir $primealndir $probalnalndir $probconsalndir $defaultProbconsalndir )
fi

#Creating a list of assessment tasks.
for ((i=0;i<${#estalnfolders[@]};++i)); do
	estfolder="${estalnfolders[i]}"

	for file in $refalndir/*.$extension; do
		filename=$(basename $file)
		if [[ ! -s $estfolder/$filename ]];then
			rm -rf $estfolder/$filename
			echo $filename does not exist in $estfolder
		fi
	done
done

for file in $refalndir/*.$extension; do
	filename=$(basename $file)
	cp $refalndir/$filename reftempfolder/
done

#Running the list of assessment tasks.
for ((i=0;i<${#lpdistarr[@]};++i)); do
	lowpdist="${lpdistarr[i]}"
	highpdist="${hpdistarr[i]}"
	csvnameextension="${csvextarr[i]}"
	
	inputstring=""
	for ((i=0;i<${#estalnfolders[@]};++i)); do
		estfolder="${estalnfolders[i]}"
		method="${methodnames[i]}"

		if [[ ! -f $method$csvnameextension.csv ]];then
			python $fastspscript -r reftempfolder -e $estfolder -l $lowpdist -u $highpdist -o $method$csvnameextension.csv #&
		
		
			if [[ $updateflag -gt 0 ]];then
				python $updatescript -i $method$csvnameextension.csv -o $method$csvnameextension.csv -r reftempfolder -e $estfolder
			fi
		fi
		inputstring=$method$csvnameextension.csv,$inputstring
	done
	wait
	
	inputstring=${inputstring%,*}
	
	python $csvavgdatacalc -i $inputstring -o $DatasetName$csvnameextension"AverageStatistics.csv" -u $DatasetName$csvnameextension"Data.csv"
done

