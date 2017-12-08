#!/bin/bash

NucleicOrAmino=Nucleic
DatasetName=BRaliBase

inputfolder=../../Datasets/DownloadedFromWeb/"$NucleicOrAmino"Acids/$DatasetName
Totalfolder=../../../Sampled/"$NucleicOrAmino"Acids/DatasetName

cd $inputfolder

if [ ! -d $Totalfolder ]; then
mkdir $Totalfolder
fi

cd $Totalfolder
Totalfolder=$(pwd)
cd - > /dev/null 2>&1

#This script is used for copying the BRaliBase alignment files into a seperate folder for further analysis
for i in * ; do
  if [ -d "$i" ]; then
	dirname=$(basename $i)
	echo $dirname
	cd $dirname
	for filename in * ; do
		number="${filename%%.fa*}"
		number="${number##*aln}"
		#checking if this number is really a number
		if [ $number -eq $number ] 2> /dev/null; then
			number=$(printf %03d $number)
			mv $filename $dirname$number.fna
			cp -rf $dirname$number.fna $Totalfolder/$dirname$number.fna
		fi
	done
	cd ..
  fi
done
