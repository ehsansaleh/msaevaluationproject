#!/bin/bash
set -e

NucleicOrAmino=Amino
DatasetName=Homstrad

samplerscript=/projects/tallis/ehsan/Python/WeirdTaxonSampler/Script.py
infolder=../../Datasets/Sampled/"$NucleicOrAmino"Acids/$DatasetName
outfolder=../../Datasets/Sampled/"$NucleicOrAmino"Acids/$DatasetName
outcsvfile=fullinfo.csv
minsampleseqs=5
maxsampleseqs=25

mkdir -p $outfolder

infolder=$(readlink -m $infolder)
outfolder=$(readlink -m $outfolder)

i=0
samples=$minsampleseqs
#This step creates a csv file with details about the sampling process
echo "Original Name,Original Number of Sequences,New Name,Number of Sampled Sequences" > $outcsvfile
for file in $(ls $infolder/*.faa); do
        filename=$(basename $file)
        datasetname=${filename%.*}
        orgseqs=$(grep ">" $file | wc -l)
        i=$((i+1))
        if [[ $orgseqs -gt 25 ]]; then
				echo $datasetname
                #echo python $samplerscript -i $file -o $outfolder/$nameprefix$inum.faa -n $samples
                python $samplerscript -i $file -o $outfolder/$datasetname-Small.faa -n $samples
                echo $datasetname,$orgseqs,$datasetname-Small.faa,$samples >> $outcsvfile

                samples=$((samples+1))
                if [[ $samples -gt $maxsampleseqs ]];then
                        samples=$minsampleseqs
                fi
        fi
done
