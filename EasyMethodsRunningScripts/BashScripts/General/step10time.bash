#!/bin/bash

 
csvfile=runtime.csv

csvfile=$(readlink -m $csvfile)
echo -n "" > $csvfile

databasearray=(MattBench Homstrad Sisyphus BAliBase)
datasetarray=(SF054 proteasome AL00048098 BALBS213)
origdir=$(pwd)

cmdpatternarr=()
methodsarr=()

methodsarr+=("MAFFT-Auto")
cmdpatternarr+=("mafft --maxiterate 1000 --thread 4 --auto INPUT_FASTA")

methodsarr+=("MAFFT-G-INS-I")
cmdpatternarr+=("mafft --maxiterate 1000 --thread 4 --globalpair INPUT_FASTA")

methodsarr+=("MAFFT-L-INS-I")
cmdpatternarr+=("mafft --maxiterate 1000 --thread 4 --localpair INPUT_FASTA")

methodsarr+=("MAFFT-E-INS-I")
cmdpatternarr+=("mafft --maxiterate 1000 --thread 4 --genafpair INPUT_FASTA")

methodsarr+=("Muscle")
cmdpatternarr+=("muscle -in INPUT_FASTA -out garbage.fasta")

methodsarr+=("Clustal-Omega")
cmdpatternarr+=("clustalw -i INPUT_FASTA -o garbage.fasta --thread=12 --full --full-iter -v")

methodsarr+=("Prank")
cmdpatternarr+=("/projects/tallis/ehsan/prank/prank -d=INPUT_FASTA -o=garbage.fasta")

methodsarr+=("ContrAlign")
cmdpatternarr+=("contralign predict INPUT_FASTA --mfa garbage.fasta")

methodsarr+=("DiAlign")
cmdpatternarr+=("dialign2-2 -fn INPUT_FASTA -fa garbage.fasta")

methodsarr+=("KAlign")
cmdpatternarr+=("kalign INPUT_FASTA garbage.fasta")

methodsarr+=("ProbAlign")
cmdpatternarr+=("probalign -prot INPUT_FASTA")

methodsarr+=("Prime")
cmdpatternarr+=("prime -i INPUT_FASTA -o garbage.fasta")

methodsarr+=("ProbCons")
cmdpatternarr+=("probcons INPUT_FASTA")

methodsarr+=("Promals")
cmdpatternarr+=("python /projects/tallis/ehsan/promals/promals_package/bin/promals INPUT_FASTA -dali 0 -tmalign 0 -fast 0")

for ((i=0;i<${#databasearray[@]};++i)); do
	dataset="${datasetarray[i]}"
	echo -n ,$dataset >> $csvfile
done
echo "" >> $csvfile

echo -n "Benchmark" >> $csvfile
for ((i=0;i<${#databasearray[@]};++i)); do
	database="${databasearray[i]}"
	echo -n ,$database >> $csvfile
done
echo "" >> $csvfile

echo -n "Number of Sequences" >> $csvfile
for ((i=0;i<${#databasearray[@]};++i)); do
        database="${databasearray[i]}"
	dataset="${datasetarray[i]}"
	maininputfasta=../../Datasets/SampledAndRenamedAndUnaligned/AminoAcids/$database/$dataset.faa
	maininputfasta=$(readlink -m $maininputfasta)
	numseq=$(grep ">" $maininputfasta | wc -l)
	echo -n ,$numseq >> $csvfile
done
echo "" >> $csvfile

echo -n "Maximum Sequence Length" >> $csvfile
for ((i=0;i<${#databasearray[@]};++i)); do
       database="${databasearray[i]}"
       dataset="${datasetarray[i]}"
       maininputfasta=../../Datasets/SampledAndRenamedAndUnaligned/AminoAcids/$database/$dataset.faa
       maininputfasta=$(readlink -m $maininputfasta)
       seqlen=$(wc -L $maininputfasta)
       seqlen=${seqlen%% *}
       echo -n ,$seqlen >> $csvfile
done
echo "" >> $csvfile

for ((j=0;j<${#methodsarr[@]};++j)); do
	method="${methodsarr[j]}"
	cmdpattern="${cmdpatternarr[j]}"

	echo -n $method >> $csvfile
	echo $method
	
	if [ $method == 'Promals' ];then
		unset MAFFT_BINARIES
	fi
	
	for ((i=0;i<${#databasearray[@]};++i)); do
		cd $origdir
		dataset="${datasetarray[i]}"
		database="${databasearray[i]}"
		maininputfasta=../../Datasets/SampledAndRenamedAndUnaligned/AminoAcids/$database/$dataset.faa
		maininputfasta=$(readlink -m $maininputfasta)
	
		#cmdpattern="mafft --maxiterate 1000 --thread 4 --auto INPUT_FASTA"

		rm -rf temprunningtime
		mkdir -p temprunningtime
		cd temprunningtime
		cp $maininputfasta ./
		inputfasta=$(pwd)/$dataset.faa
		cmd=$(sed "s|INPUT_FASTA|$inputfasta|g" <<< $cmdpattern)
		/usr/bin/time -v $cmd > garbage.output 2> error.output
		timeline=$(grep "Elapsed (wall clock) time (h:mm:ss or m:ss): " error.output)
		comptime=${timeline##*m:ss):}

		seconds=${comptime##*:}
		restvar=${comptime%:*}
		minutes=${restvar##*:}
		hours=${restvar%:*}
		
		mytimeformat=""$(printf %02.2f $seconds)"s"
		if [[ $minutes -gt 0 ]] || [[ -z $hours ]];then
			mytimeformat="$minutes"m" "$mytimeformat
		fi

		if [ ! -z $hours ];then
			mytimeformat="$hours"h" "$mytimeformat
		fi
		echo -n ,$mytimeformat >> $csvfile
		echo -n $comptime,
done
	echo "" >> $csvfile
	echo ""
	echo "-----------"
	#read ok

done

