#!/bin/bash

qsub -V step3.x3.bash -F "Amino BAliBase 27" -t 0-26
qsub -V step3.x3.bash -F "Amino MattBench 10" -t 0-9
qsub -V step3.x3.bash -F "Amino Homstrad 9" -t 0-8
qsub -V step3.x3.bash -F "Amino Sisyphus 5" -t 0-4
