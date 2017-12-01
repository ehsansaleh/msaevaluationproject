#!/usr/local/python/2.7.11/bin/python
import sys
import numpy as np
import subprocess, os, re

sys.path.append('/projects/tallis/ehsan/MikeUtilities/')
import alignment_utils as au
import xlsxwriter, argparse
import PDist
import tempfile, shutil
from subprocess import Popen, PIPE
from CompareTree import CompareTree

parser = argparse.ArgumentParser()
parser.add_argument('-r', '--reffasta', type=str, default='RefFasta', help='Name of reference aligned fasta folder.')
parser.add_argument('-e', '--estfasta', type=str, default='EstFasta', help='Name of estimated aligned fasta folder.')
parser.add_argument('-t', '--reftree', type=str, default='RefTree', help='Name of reference tree folder.')
parser.add_argument('-m', '--esttree', type=str, default='EstTree', help='Name of estimated tree folder.')
parser.add_argument('-o', '--output', type=str, default='statistics.csv', help='Name of output csv file.')
parser.add_argument('-l', '--lowpdistlimit', type=float, default=0,
                    help='Low Average P-distance limit. Datasets with less than this limit will not be considered.')
parser.add_argument('-u', '--highpdistlimit', type=float, default=1,
                    help='High Average P-distance limit. Datasets with more than this limit will not be considered.')
parser.add_argument('-w', '--likelihoodreport', type=int, default=0,
                    help='Set it to one if you want the likelihoodreports.')

args = parser.parse_args()

ref_align_folder = args.reffasta
est_align_folder = args.estfasta
ref_tree_folder = args.reftree
est_tree_folder = args.esttree
lowpdistlimint = args.lowpdistlimit
highpdistlimint = args.highpdistlimit
outcsv = args.output

likelihoodreport = args.likelihoodreport

DType = 'NT'  # Doesn't matter much, it's fine if it's set wrong...
reportAlnStat = True
reportTreeStat = False


def hetcalc(data):
    lenlist = []
    for seq in data:
        lenlist.append(len(data[seq].replace('-', '')))
    return float(np.std(lenlist, ddof=1) / np.median(lenlist))


def gapfrac(data):
    gapcount = 0
    for seq in data:
        gapcount = gapcount + data[seq].count('-')
    return float(gapcount) / (len(data.keys()) * len(data[data.keys()[0]]))


def gaplenstat(data):
    gaplist = []
    for taxon in data:
        seq = data[taxon]
        ingapflag = False
        for i, state in enumerate(seq):
            if ingapflag == False and state == '-':
                ingapflag = True
                currgaplen = 0
            if ingapflag == True and state == '-':
                currgaplen = currgaplen + 1
            if ingapflag == True and not (state == '-'):
                gaplist.append(currgaplen)
                ingapflag = False
        if ingapflag == True:
            gaplist.append(currgaplen)
    if len(gaplist)>0:
        return (np.median(gaplist)), (np.mean(gaplist))
    else:
        return 0,0


if (DType == 'NT'):
    AvgPdistFunc = PDist.NTmsa2avgpdist
    MaxPdistFunc = PDist.NTmsa2maxpdist
else:
    AvgPdistFunc = PDist.AAmsa2avgpdist
    MaxPdistFunc = PDist.AAmsa2maxpdist

if not (ref_align_folder[-1] == '/'):
    ref_align_folder = ref_align_folder + '/'
if not (est_align_folder[-1] == '/'):
    est_align_folder = est_align_folder + '/'
if not (ref_tree_folder[-1] == '/'):
    ref_tree_folder = ref_tree_folder + '/'
if not (est_tree_folder[-1] == '/'):
    est_tree_folder = est_tree_folder + '/'

NamesRow = ['']
# SPFP=['SPFP']
# SPFN=['SPFN']
SPFP = ['1-SPFP']
SPFN = ['1-SPFN']
SPScore = ['SP-Score']
TC = ['TC']
Modeler = ['Modeler']
Compression = ['Compression']
NumSeq = ['Number of Sequences']
ReferenceLen = ['Reference Length']
EstLen = ['Estimated Length']
MaxLen = ['Maximum Ungapped Length']
AveragePDist = ['Average Pairwise P-Distance']
MaxPDist = ['Maximum Pairwise P-Distance']
lenhet = ['Sequence Length Heterogeneity']
RefIdnt = ['Reference Alignment Identity']
EstIdnt = ['Estimated Alignment Identity']
RefSim = ['Reference Alignment Similarity']
EstSim = ['Estimated Alignment Similarity']
GapPercent = ['Gappiness Percentage']
GapLenMean = ['Average Gap Length']
GapLenMedian = ['Median Gap Length']

if likelihoodreport:
    estll = ['Estimated Negative Likelihood']
    estllpersite = ['Estimated Negative Likelihood Per Site']

for root, dirs, files in os.walk(ref_align_folder):
    for file in files:
        if file.endswith('.fasta') or file.endswith('.fna') or file.endswith('.faa'):
            if file.endswith('.fasta'):
                extension = '.fasta'
                fastaname = file[0:-6]
            if file.endswith('.fna'):
                extension = '.fna'
                fastaname = file[0:-4]
                AvgPdistFunc = PDist.NTmsa2avgpdist
                MaxPdistFunc = PDist.NTmsa2maxpdist
            if file.endswith('.faa'):
                extension = '.faa'
                fastaname = file[0:-4]
                # AvgPdistFunc = PDist.NTmsa2avgpdist
                # MaxPdistFunc = PDist.NTmsa2maxpdist
                # We're using the strict notion of p-distance here
                AvgPdistFunc = PDist.NTmsa2avgpdist
                MaxPdistFunc = PDist.NTmsa2maxpdist

            if not (os.path.exists(est_align_folder + fastaname + extension)):
                # the estimated alignment does not exist...
                continue

            refFasta = au.read_from_fasta(ref_align_folder + fastaname + extension)
            if (AvgPdistFunc(refFasta) < lowpdistlimint or AvgPdistFunc(refFasta) > highpdistlimint):
                continue
            print(est_align_folder + fastaname + extension)
            estFasta = au.read_from_fasta(est_align_folder + fastaname + extension)
            problem = False
            for seq in refFasta:
                if not (seq in estFasta):
                    SPFP.append("Taxa don't match.")
                    SPFN.append("Taxa don't match.")
                    SPScore.append("Taxa don't match.")
                    TC.append("Taxa don't match.")
                    Modeler.append("Taxa don't match.")
                    Compression.append("Taxa don't match.")
                    NumSeq.append("Taxa don't match.")
                    ReferenceLen.append("Taxa don't match.")
                    EstLen.append("Taxa don't match.")
                    MaxLen.append("Taxa don't match.")
                    AveragePDist.append("Taxa don't match.")
                    MaxPDist.append("Taxa don't match.")
                    lenhet.append("Taxa don't match.")
                    RefIdnt.append("Taxa don't match.")
                    EstIdnt.append("Taxa don't match.")
                    RefSim.append("Taxa don't match.")
                    EstSim.append("Taxa don't match.")
                    GapPercent.append("Taxa don't match.")
                    GapLenMean.append("Taxa don't match.")
                    GapLenMedian.append("Taxa don't match.")
                    if likelihoodreport:
                        estll.append("Taxa don't match.")
                        estllpersite.append("Taxa don't match.")
                    problem = True
                    break

                refunaln = refFasta[seq].replace("-", "").upper()
                estunaln = estFasta[seq].replace("-", "").upper()
                if not (refunaln == estunaln):

                    SPFP.append("Sequece " + seq + " Does not match")
                    SPFN.append("Sequece " + seq + " Does not match")
                    SPScore.append("Sequece " + seq + " Does not match")
                    TC.append("Sequece " + seq + " Does not match")
                    Modeler.append("Sequece " + seq + " Does not match")
                    Compression.append("Sequece " + seq + " Does not match")
                    NumSeq.append("Sequece " + seq + " Does not match")
                    ReferenceLen.append("Sequece " + seq + " Does not match")
                    EstLen.append("Sequece " + seq + " Does not match")
                    MaxLen.append("Sequece " + seq + " Does not match")
                    AveragePDist.append("Sequece " + seq + " Does not match")
                    MaxPDist.append("Sequece " + seq + " Does not match")
                    lenhet.append("Sequece " + seq + " Does not match")
                    RefIdnt.append("Sequece " + seq + " Does not match")
                    EstIdnt.append("Sequece " + seq + " Does not match")
                    RefSim.append("Sequece " + seq + " Does not match")
                    EstSim.append("Sequece " + seq + " Does not match")
                    GapPercent.append("Sequece " + seq + " Does not match")
                    GapLenMean.append("Sequece " + seq + " Does not match")
                    GapLenMedian.append("Sequece " + seq + " Does not match")
                    if likelihoodreport:
                        estll.append("Sequece " + seq + " Does not match")
                        estllpersite.append("Sequece " + seq + " Does not match")
                    problem = True

            NamesRow.append(fastaname)
            if (problem):
                continue

            if (reportAlnStat):
                refFasta = au.read_from_fasta(ref_align_folder + fastaname + extension)
                estFasta = au.read_from_fasta(est_align_folder + fastaname + extension)

                mylenhet = hetcalc(refFasta)

                reftaxaset = set(refFasta.keys())
                esttaxonlist = estFasta.keys()
                for taxon in esttaxonlist:
                    if not (taxon in reftaxaset):
                        estFasta.pop(taxon)
                au.write_to_fasta(out_file_path=est_align_folder + fastaname + extension, fasta_dict=estFasta,
                                  raw=False)

                AlnStats = au.fastsp_run_on_two_fastas(ref_align_folder + fastaname + extension,
                                                       est_align_folder + fastaname + extension, printRestults=False,
                                                       outFile='miketempfile' + fastaname + '_' + outcsv.split('/')[
                                                           -1] + '_' + '.txt')

                resultsprobem = False
                if (AlnStats['spfp'] == '' and not resultsprobem):
                    print('there is a problem with spfp of the dataset ' + ref_align_folder + fastaname + extension)
                    resultsprobem = True
                if (AlnStats['spfn'] == '' and not resultsprobem):
                    print('there is a problem with spfn of the dataset ' + ref_align_folder + fastaname + extension)
                    resultsprobem = True
                if (AlnStats['tc'] == '' and not resultsprobem):
                    print('there is a problem with tc of the dataset ' + ref_align_folder + fastaname + extension)
                    resultsprobem = True
                if (AlnStats['modeler'] == '' and not resultsprobem):
                    print('there is a problem with modeler of the dataset ' + ref_align_folder + fastaname + extension)
                    resultsprobem = True

                if resultsprobem:
                    fastspout = au.just_output_fastsp_results_on_two_fastas(ref_align_folder + fastaname + extension,
                                                                            est_align_folder + fastaname + extension,
                                                                            outFile='miketempfile' + fastaname + '_' +
                                                                                    outcsv.split('/')[
                                                                                        -1] + '_' + '.txt')
                    # print fastspout
                    fastspout = fastspout.splitlines()
                    for line in fastspout:

                        if line.startswith('SPFP'):
                            if line.split(' ')[1] == 'NaN':
                                AlnStats['spfp'] = '1'
                            else:
                                AlnStats['spfp'] = line.split(' ')[1]

                        if line.startswith('SPFN'):
                            if line.split(' ')[1] == 'NaN':
                                AlnStats['spfn'] = '1'
                            else:
                                AlnStats['spfn'] = line.split(' ')[1]

                        if line.startswith('TC'):
                            if line.split(' ')[1] == 'NaN':
                                AlnStats['tc'] = '0'
                            else:
                                AlnStats['tc'] = line.split(' ')[1]

                        if line.startswith('Modeler'):
                            if line.split(' ')[1] == 'NaN':
                                AlnStats['modeler'] = '0'
                            else:
                                AlnStats['modeler'] = line.split(' ')[1]

                        if line.startswith('SP-Score'):
                            if line.split(' ')[1] == 'NaN':
                                AlnStats['sp'] = '0'
                            else:
                                AlnStats['sp'] = line.split(' ')[1]

                        if line.startswith('Compression'):
                            AlnStats['comp'] = line.split(' ')[1]


                            # print AlnStats
                            # print '----------'

                SPFP.append(str(1.0 - float(AlnStats['spfp'])))
                SPFN.append(str(1.0 - float(AlnStats['spfn'])))
                # SPFN.append(AlnStats['spfn'])
                # SPFP.append(AlnStats['spfp'])
                SPScore.append(str(1.0 - (float(AlnStats['spfp']) + float(AlnStats['spfn'])) / 2))
                TC.append(AlnStats['tc'])
                Modeler.append(AlnStats['modeler'])
                Compression.append(AlnStats['comp'])
                NumSeq.append(AlnStats['numseq'])
                ReferenceLen.append(AlnStats['lenref'])
                EstLen.append(AlnStats['lenest'])
                MaxLen.append(AlnStats['maxlen'])
                AveragePDist.append(str(AvgPdistFunc(refFasta)))
                MaxPDist.append(str(MaxPdistFunc(refFasta)))
                lenhet.append(str(mylenhet))
                RefIdnt.append(str(1 - AvgPdistFunc(refFasta)))
                EstIdnt.append(str(1 - AvgPdistFunc(estFasta)))
                RefSim.append(str(1 - PDist.AAmsa2avgpdist(refFasta)))
                EstSim.append(str(1 - PDist.AAmsa2avgpdist(estFasta)))
                GapPercent.append(str(gapfrac(refFasta)))
                gapmedian, gapmean = gaplenstat(refFasta)
                GapLenMedian.append(str(gapmedian))
                GapLenMean.append(str(gapmean))

                if (likelihoodreport):
                    mytempdir = tempfile.mkdtemp()
                    myestfasta = estFasta
                    estalilen = len(myestfasta[myestfasta.keys()[0]])
                    # adding taxa till they surpass four
                    while len(myestfasta.keys()) < 4:
                        mytaxa = myestfasta.keys()
                        for mytaxon in mytaxa:
                            myestfasta['Dup_' + mytaxon] = myestfasta[mytaxon]
                    au.write_to_fasta(out_file_path=mytempdir + '/' + fastaname + extension, fasta_dict=myestfasta,
                                      raw=False)
                    cmd = 'cd ' + mytempdir + '; raxml -f a -p 12345 -x 12345 -m PROTGAMMAIAUTO -N 1 -s ' + mytempdir + \
                          '/' + fastaname + extension + ' -n MODEL_' + \
                          fastaname + '_Selection | grep "Final ML Optimization Likelihood"'
                    mycmd = Popen(cmd, shell=True, stdout=PIPE)
                    output = (mycmd.stdout.read())
                    outlines = output.splitlines()
                    rawll = (-1) * float(outlines[0].split()[-1])
                    estll.append(str(rawll))
                    estllpersite.append(str(rawll / estalilen))
                    # shutil.rmtree(mytempdir)
            if (reportTreeStat):
                TreeStats = CompareTree(ref_tree_file=ref_tree_folder + fastaname + '.nwk',
                                        est_tree_file=est_tree_folder + fastaname + '.nwk')

file = open(outcsv, 'w')
file.write(','.join(NamesRow) + '\n')
if (reportAlnStat):
    file.write(','.join(SPFP) + '\n')
    file.write(','.join(SPFN) + '\n')
    file.write(','.join(SPScore) + '\n')
    file.write(','.join(TC) + '\n')
    file.write(','.join(Modeler) + '\n')
    file.write(','.join(Compression) + '\n')
    file.write(','.join(AveragePDist) + '\n')
    file.write(','.join(MaxPDist) + '\n')
    file.write(','.join(NumSeq) + '\n')
    file.write(','.join(ReferenceLen) + '\n')
    file.write(','.join(EstLen) + '\n')
    file.write(','.join(MaxLen) + '\n')
    file.write(','.join(lenhet) + '\n')
    file.write(','.join(GapPercent) + '\n')
    file.write(','.join(GapLenMean) + '\n')
    file.write(','.join(GapLenMedian) + '\n')
    if (likelihoodreport):
        file.write(','.join(estll) + '\n')
        file.write(','.join(estllpersite) + '\n')

file.close()