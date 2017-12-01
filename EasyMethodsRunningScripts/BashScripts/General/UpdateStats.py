#!/usr/local/python/2.7.11/bin/python
import sys
import numpy as np
import os
import pandas as pd
sys.path.append('/projects/tallis/ehsan/MikeUtilities/')
import alignment_utils as au
import argparse
import PDist
import itertools
import operator
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('-r', '--reffasta', type=str, default='RefFasta', help='Name of reference aligned fasta folder.')
parser.add_argument('-e', '--estfasta', type=str, default='EstFasta', help='Name of estimated aligned fasta folder.')
parser.add_argument('-i', '--input', type=str, default='statistics.csv', help='Name of input updatable csv file.')
parser.add_argument('-o', '--output', type=str, default='statistics.csv', help='Name of output updated csv file.')

args = parser.parse_args()

ref_align_folder = args.reffasta
est_align_folder = args.estfasta
incsv=args.input
outcsv = args.output

AvgPdistFunc = PDist.NTmsa2avgpdist
MaxPdistFunc = PDist.NTmsa2maxpdist


def max_most_common(L):
    # get an iterable of (item, iterable) pairs
    SL = sorted((x, i) for i, x in enumerate(L))
    # print 'SL:', SL
    groups = itertools.groupby(SL, key=operator.itemgetter(0))

    # auxiliary function to get "quality" for an item
    def _auxfun(g):
        item, iterable = g
        count = 0
        min_index = len(L)
        for _, where in iterable:
            count += 1
            min_index = min(min_index, where)
        # print 'item %r, count %r, minind %r' % (item, count, min_index)
        return count, -min_index

    # pick the highest-count/earliest item
    return max([_auxfun(el)[0] for el in groups])
    # return max(groups, key=_auxfun)[0]

def modify_Avgpdist_func(myreffasta,myestfasta,oldvalslist):
    return [AvgPdistFunc(myreffasta)]
def modify_Maxpdist_func(myreffasta,myestfasta,oldvalslist):
    return [MaxPdistFunc(myreffasta)]
def add_avgterminalgap_func(myreffasta,myestfasta,oldvalslist):
    terminalgaps=[]
    for key in myreffasta:
        charpos=[p for p, ltr in enumerate(myreffasta[key]) if not ltr=='-']
        terminalgaps.append(charpos[0])
        terminalgaps.append(len(myreffasta[key])-1-charpos[-1])

    return [float(sum(terminalgaps))/len(terminalgaps)]
def add_efflen_func(myreffasta,myestfasta,oldvalslist):
    threshold=0.5
    n=len(myreffasta)
    alnlen=len(myreffasta[myreffasta.keys()[0]])
    consensusFracList=[]
    for k,kval in enumerate(range(alnlen)):
        charslist=[]
        for key in myreffasta:
            charslist.append(myreffasta[key][k])
        charslist[:] = [x for x in charslist if x != '-']
        consensusFracList.append(float(max_most_common(charslist))/n)
    consposlist=[i for i,val in enumerate(consensusFracList) if val*(n-1)/n>threshold]
    consposlist=[-1]+consposlist+[alnlen]
    efflenlist=[consposlist[i+1]-consposlist[i]-1 for i in range(len(consposlist)-1)]
    return [max(efflenlist)]
def add_mlr_fastsp_values(myreffasta, myestfasta, oldvalslist):
    mikeutiltempad1d, mikeutiltempad1 = tempfile.mkstemp()
    mikeutiltempfile1 = os.fdopen(mikeutiltempad1d)
    mikeutiltempad2d, mikeutiltempad2 = tempfile.mkstemp()
    mikeutiltempfile2 = os.fdopen(mikeutiltempad2d)

    reftemp = tempfile.NamedTemporaryFile()
    esttemp = tempfile.NamedTemporaryFile()
    #mikeutiltempfile1 = tempfile.NamedTemporaryFile()
    #mikeutiltempfile2 = tempfile.NamedTemporaryFile()

    #mikeutiltempad1 = mikeutiltempfile1.name
    #mikeutiltempad2 = mikeutiltempfile2.name
    reftempadress = reftemp.name
    esttempadress = esttemp.name

    au.write_to_fasta(out_file_path=reftempadress, fasta_dict=myreffasta, raw=False)
    au.write_to_fasta(out_file_path=esttempadress, fasta_dict=myestfasta, raw=False)

    myoutstring = []
    refFasta = au.read_from_fasta(reftempadress)
    estFasta = au.read_from_fasta(esttempadress)
    problem = False
    for seq in refFasta:
        if not (seq in estFasta):
            myoutstring = ['Taxa dont match' for y in range(4)]
            problem = True
            break
        refunaln = refFasta[seq].replace("-", "").upper()
        estunaln = estFasta[seq].replace("-", "").upper()
        if not (refunaln == estunaln):
            myoutstring = ["Sequece " + seq + " Does not match" for y in range(4)]
            problem = True
            break

    if problem:
        reftemp.close()
        esttemp.close()
        mikeutiltempfile1.close()
        mikeutiltempfile2.close()
        return myoutstring

    reftaxaset = set(refFasta.keys())
    esttaxonlist = estFasta.keys()
    for taxon in esttaxonlist:
        if not (taxon in reftaxaset):
            estFasta.pop(taxon)
    AlnStats = au.fastsp_run_on_two_fastas_mlr(reftempadress,
                                               esttempadress, printRestults=False,
                                               outFile=mikeutiltempad1)
    resultsprobem = False
    if (AlnStats['spfp'] == '' and not resultsprobem):
        print('there is a problem with spfp of the dataset ' + reftempadress)
        resultsprobem = True
    if (AlnStats['spfn'] == '' and not resultsprobem):
        print('there is a problem with spfn of the dataset ' + reftempadress)
        resultsprobem = True
    if (AlnStats['tc'] == '' and not resultsprobem):
        print('there is a problem with tc of the dataset ' + reftempadress)
        resultsprobem = True
    if (AlnStats['modeler'] == '' and not resultsprobem):
        print('there is a problem with modeler of the dataset ' + reftempadress)
        resultsprobem = True

    if resultsprobem:
        fastspout = au.just_output_fastsp_results_on_two_fastas(reftempadress, esttempadress, outFile=mikeutiltempad2)
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

    outlist=[]
    outlist.append(str(1.0 - float(AlnStats['spfp'])))
    outlist.append(str(1.0 - float(AlnStats['spfn'])))
    outlist.append(AlnStats['tc'])
    outlist.append(AlnStats['comp'])
    if os.path.exists(reftemp.name):
        reftemp.close()
    if os.path.exists(esttemp.name):
        esttemp.close()
    if os.path.exists(mikeutiltempfile1.name):
        mikeutiltempfile1.close()
    if os.path.exists(mikeutiltempfile2.name):
        mikeutiltempfile2.close()
    return outlist

correctiondict={
#    'Average Pairwise P-Distance':modify_Avgpdist_func,
#    'Maximum Pairwise P-Distance':modify_Maxpdist_func,
    'Average Terminal Gap length':add_avgterminalgap_func,
#    'Maximum Effective Alignment Length':add_efflen_func,
    '1-SPFP(masked)//1-SPFN(masked)//TC(masked)//Compression(masked)':add_mlr_fastsp_values
}

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

if not (ref_align_folder[-1] == '/'):
    ref_align_folder = ref_align_folder + '/'
if not (est_align_folder[-1] == '/'):
    est_align_folder = est_align_folder + '/'

def checkproblem(reffile, estfile):
    myRefFasta = au.read_from_fasta(reffile)
    myEstFasta = au.read_from_fasta(estfile)
    problem = 0
    backupiter = myRefFasta.keys()
    for seq in backupiter:
        if not (seq in myEstFasta):
            print('Warning: Taxa dont match. sequence ' + seq + ' is not found in the estimated alignment.')
            print('Estimated Alignment: ' + estfile)
            print('Reference Alignment: ' + reffile)
            print('We might discard this sequence from the reference alignment. '
                  'All the process will be affected by this decision, including identity calculation, etc.')
            print('----------')
            myRefFasta.pop(seq)
            problem = max(problem, 1)

    backupiter = myEstFasta.keys()
    for seq in backupiter:
        if not (seq in myRefFasta):
            print('Warning: Taxa dont match. sequence ' + seq + ' is not found in the reference alignment.')
            print('Estimated Alignment: ' + estfile)
            print('Reference Alignment: ' + reffile)
            print('We might discard this sequence from the estimated alignment.')
            print('----------')
            myEstFasta.pop(seq)
            problem = max(problem, 1)

    backupiter = myRefFasta.keys()
    for seq in backupiter:
        refunaln = myRefFasta[seq].replace("-", "").upper()
        estunaln = myEstFasta[seq].replace("-", "").upper()
        if not (refunaln == estunaln):
            print ("Important Warning: Sequece " + seq + " Does not match in the refernce and estimated alignment.")
            print('Estimated Alignment: ' + estfile)
            print('Reference Alignment: ' + reffile)
            print('The process will skip this file.')
            print('----------')
            problem = max(problem, 2)
            break

    return problem, myRefFasta, myEstFasta

inputdf = pd.read_csv(incsv)
if not 'Statistics' in inputdf:
    inputdf.rename(columns={"Unnamed: 0":'Statistics'},inplace=True)

updatedict={}
for bigkey in correctiondict:
    for key in bigkey.split('//'):
        updatedict[key]={}
        for col in list(inputdf):
            if not col=='Statistics':
                updatedict[key][col]=False

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
                AvgPdistFunc = PDist.NTmsa2avgpdist
                MaxPdistFunc = PDist.NTmsa2maxpdist
            print(est_align_folder + fastaname + extension)

            if not (os.path.exists(est_align_folder + fastaname + extension)):
                print ("Warning: Estimated Alignment File does not exist.")
                print('Estimated Alignment: ',est_align_folder + fastaname + extension)
                print('The process will skip this file.')
                print('----------')
                continue

            problem, refFasta, estFasta = checkproblem(ref_align_folder + fastaname + extension, est_align_folder + fastaname + extension)

            if (problem):
                continue

            if fastaname in inputdf:
                for fullstatname in correctiondict.keys():
                    statfunc=correctiondict[fullstatname]

                    allstatpresent=True
                    for partialstat in fullstatname.split('//'):
                        if not (inputdf['Statistics'] == partialstat).any():
                            allstatpresent=False

                    for partialstat in fullstatname.split('//'):
                        if not allstatpresent:
                            inputdf=inputdf[inputdf['Statistics']!=partialstat]

                    if allstatpresent:
                        oldvalslist=[]
                        for u,statname in enumerate(fullstatname.split('//')):
                            criterion=inputdf['Statistics'].map(lambda x: statname==x)
                            rowindexes =inputdf[criterion].index[:]
                            rowidx=rowindexes[0]
                            oldvalslist.append(inputdf.loc[rowidx, fastaname])

                        allouts=statfunc(refFasta, estFasta, oldvalslist)
                        for u,statname in enumerate(fullstatname.split('//')):
                            criterion=inputdf['Statistics'].map(lambda x: statname==x)
                            rowindexes =inputdf[criterion].index[:]
                            rowidx=rowindexes[0]

                            inputdf.set_value(rowidx, fastaname, allouts[u])

                            updatedict[statname][fastaname] = True
                    else:
                        #The statistics row does not exist, we have to add it.
                        oldvalslist = []
                        for u, statname in enumerate(fullstatname.split('//')):
                            oldvalslist.append('Nothing!')
                        newout=statfunc(refFasta, estFasta, oldvalslist)

                        for u, statname in enumerate(fullstatname.split('//')):
                            inputdf.loc[len(inputdf.index)] = 0
                            inputdf.reset_index(inplace=True,drop=True)
                            inputdf.iloc[-1, inputdf.columns.get_loc('Statistics')] = statname
                            inputdf.iloc[-1, inputdf.columns.get_loc(fastaname)] = newout[u]
                            updatedict[statname][fastaname]=True


            else:
                print('Warning: Estimated Reference Alignment '+fastaname+' does not exist in input csv file. We will skip it')
for currstat in updatedict:
    for currfasta,val in updatedict[currstat].iteritems():
        if val==False:
            print('Warning: The value of ' + currstat +' for '+currfasta+
                  ' was not updated. It is either obsolete or completely wrong.')

inputdf.to_csv(outcsv,index=False)