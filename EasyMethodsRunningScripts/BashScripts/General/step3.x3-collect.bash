#!/bin/bash

 

NucleicOrAmino=Amino
#for DatasetName in Sisyphus MattBench Homstrad BAliBase; do
DatasetName=SubSampled
	echo $DatasetName

	inputdir=../../ProcessedData/PromalsFiles/"$NucleicOrAmino"Acids/$DatasetName
	outputdir=../../ProcessedData/PromalsAlignments/"$NucleicOrAmino"Acids/$DatasetName

	mkdir -p $outputdir

	cd $inputdir
	inputdir=$(pwd)
	cd - > /dev/null 2>&1

	cd $outputdir
	outputdir=$(pwd)
	cd - > /dev/null 2>&1

	for dataset in $(ls $inputdir);do
		echo $dataset
		if [ -s $inputdir/$dataset/$dataset.faa.promals.aln ]; then
			t_coffee -other_pg seq_reformat -in=$inputdir/$dataset/$dataset.faa.promals.aln -output fasta_aln > $outputdir/$dataset.faa
		fi
	done

#done
