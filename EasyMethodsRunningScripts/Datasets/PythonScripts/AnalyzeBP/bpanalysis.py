from subprocess import Popen,PIPE
import re
import argparse

parser=argparse.ArgumentParser()
parser.add_argument('-i','--input_folder',type=str,default='input',help='Name of input datasets folder.')
parser.add_argument('-o','--outputcsvname',type=str,default='BPStatistics.csv',help='Name of output CSV file.')
args=parser.parse_args()

inputpath=args.input_folder
outcsv=args.outputcsvname

#inputpath='/mnt/a/u/sciteam/saleh1/tempcrap/crap'
#outcsv='BPStatistics.csv'

#Removing any prior Results folder
p1 = Popen("rm -rf *Results*", shell=True, stdout=PIPE)
mystr = (p1.stdout.read())

def analyzedataset(datasetname,inputpath):
    command= "bp-analyze.pl " + inputpath + datasetname + "-*"
    p1 = Popen(command, shell=True, stdout=PIPE)
    #p1 = Popen("cat output.log", shell=True, stdout=PIPE)
    mystr = (p1.stdout.read())

    outlines = mystr.splitlines()
    burnin = ''
    essscalar = ''
    ASDSF = ''
    MSDSF = ''
    PSRF80CI = ''
    PSRFRCF = ''
    esspartition = ''
    for line in outlines:
        if (line.startswith('NOTE: min_Ne (scalar)')):
            essscalar = re.sub(r'.*= ', '', line)
        if (line.startswith('NOTE: min_Ne (partition)')):
            esspartition = re.sub(r'.*= ', '', line)
        if (line.startswith('NOTE: ASDSF')):
            ASDSF = re.sub(r'.*= ', '', line)
        if (line.startswith('NOTE: MSDSF')):
            MSDSF = re.sub(r'.*= ', '', line)
        if (line.startswith('NOTE: PSRF-80%CI')):
            PSRF80CI = re.sub(r'.*= ', '', line)
        if (line.startswith('NOTE: PSRF-RCF')):
            PSRFRCF = re.sub(r'.*= ', '', line)
        if (line.startswith('NOTE: burnin (scalar)')):
            burnin = re.sub(r'.*= ', '', line)

    if (burnin == ''):
        print('bpanalyze is not returning good things. print mystr to see what it is outputting...')
    #print('burnin is : ' + str(burnin))
    #print('essscalar is : ' + str(essscalar))
    #print('esspartition is : ' + str(esspartition))
    #print('ASDSF is : ' + str(ASDSF))
    #print('PSRF80CI is : ' + str(PSRF80CI))
    #print('PSRFRCF is : ' + str(PSRFRCF))
    #print('MSDSF is : ' + str(MSDSF))
    

    # Removing Results after completion
    p1 = Popen("rm -rf *Results*", shell=True, stdout=PIPE)
    mystr = (p1.stdout.read())

    return burnin, essscalar, esspartition, ASDSF, MSDSF, PSRF80CI, PSRFRCF



if not(inputpath[-1]=='/'):
    inputpath=inputpath+'/'

csvfile = open(outcsv, "w")
datasetRow=','
indeprunsrow='Independent Runs,'
burninrow='Burnin iterations,'
essscalarrow='ESS(Scalar),'
esspartitionrow='ESS(Partition),'
ASDSFrow='ASDSF,'
MSDSFrow='MSDSF,'
PSRF80CIrow='PSRF-80%CI,'
PSRFRCFrow='PSRF-RCF,'

lsing=Popen('ls -d '+inputpath+'*-*',shell=True,stdout=PIPE)
dirlist=(lsing.stdout.read())
candidates=dirlist.split()
candidates=[name.split('/')[-1] for name in candidates]
while(len(candidates)):
    rawfirst=candidates[0]
    datasetname=rawfirst.split('-', 1)[0]

    idxlist=[]
    for i in range(len(candidates)):
        if(candidates[i].startswith(datasetname)):
            idxlist.append(i)
    idxlist.reverse()
    folders=[]
    for i in range(len(idxlist)):
        folders.append(candidates.pop(idxlist[i]))
    print datasetname

    burnin, essscalar, esspartition, ASDSF, MSDSF, PSRF80CI, PSRFRCF = analyzedataset(datasetname,inputpath)

    datasetRow = datasetRow + datasetname +','
    indeprunsrow = indeprunsrow + str(len(folders)) + ','
    burninrow = burninrow + burnin + ','
    essscalarrow = essscalarrow + essscalar + ','
    esspartitionrow = esspartitionrow + esspartition + ','
    ASDSFrow = ASDSFrow + ASDSF + ','
    MSDSFrow = MSDSFrow + MSDSF + ','
    PSRF80CIrow = PSRF80CIrow + PSRF80CI + ','
    PSRFRCFrow = PSRFRCFrow + PSRFRCF +','
    print '-------'

csvfile.write(datasetRow+'\n')
csvfile.write(indeprunsrow+'\n')
csvfile.write(burninrow+'\n')
csvfile.write(essscalarrow+'\n')
csvfile.write(esspartitionrow+'\n')
csvfile.write(ASDSFrow+'\n')
csvfile.write(MSDSFrow+'\n')
csvfile.write(PSRF80CIrow+'\n')
csvfile.write(PSRFRCFrow+'\n')


csvfile.close()
