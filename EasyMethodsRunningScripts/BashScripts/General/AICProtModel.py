import argparse, os, re,time,sys,random
from subprocess import Popen, PIPE
from math import log

parser = argparse.ArgumentParser()
parser.add_argument('-i', '--input', type=str, default='test.fasta', help='Name of input file.')
parser.add_argument('-c', '--criterion', type=str, default='aic',
                    help='model selection criteria(either aic, bic or lrt).')
parser.add_argument('-m', '--models', type=str, default='All',
                    help='Models for test(for instance put JTT:WAG:LG to test these three models).'
                         ' Otherwise it would test all possible models which are DAYHOFF,DCMUT,JTT,'
                         'MTREV,WAG,RTREV,CPREV,VT,BLOSUM62,MTMAM,LG,MTART,MTZOA,PMB,HIVB,HIVW,'
                         'JTTDCMUT,FLU,DAYHOFFF,DCMUTF,JTTF,MTREVF,WAGF,RTREVF,CPREVF,VTF,BLOSUM62F,'
                         'MTMAMF,LGF,MTARTF,MTZOAF,PMBF,HIVBF,HIVWF,JTTDCMUTF,FLUF')
parser.add_argument('-r', '--raxmlexec', type=str, default='raxml',
                    help='raxml executable address (version 8.2.9 preferred)')
args = parser.parse_args()

alignmentName = args.input
modelcands = args.models
criterion = args.criterion
raxmlExecutable = args.raxmlexec



if modelcands == 'All':
    AAModels = ["DAYHOFF", "DCMUT", "JTT", "MTREV", "WAG", "RTREV", "CPREV", "VT", "BLOSUM62", "MTMAM", "LG", "MTART",
                "MTZOA", "PMB", "HIVB", "HIVW", "JTTDCMUT", "FLU", "DAYHOFFF", "DCMUTF", "JTTF", "MTREVF", "WAGF",
                "RTREVF", "CPREVF", "VTF", "BLOSUM62F", "MTMAMF", "LGF", "MTARTF", "MTZOAF", "PMBF", "HIVBF", "HIVWF",
                "JTTDCMUTF", "FLUF"]
else:
    AAModels = modelcands.split(':')
	
mycmd = Popen('cp -rf ' + alignmentName + ' temp.fasta', shell=True, stdout=PIPE)
output = (mycmd.stdout.read())
alignmentName='temp.fasta'

mycmd = Popen('grep ">" < temp.fasta | wc -l', shell=True, stdout=PIPE)
seqnum = int(mycmd.stdout.read())
if seqnum<4:
    if 'LG' in modelcands:
        print('LG')
    else:
        print(modelcands[1])
    sys.exit(0)

mycmd = Popen('rm -rf *_EVAL *ST_' + alignmentName + ' ' + alignmentName + '.reduced', shell=True, stdout=PIPE)
output = (mycmd.stdout.read())

cmd = raxmlExecutable + " -y -p 12345 -m PROTCATJTT -s " + alignmentName + " -n ST_" + alignmentName
mycmd = Popen(cmd, shell=True, stdout=PIPE)
output = (mycmd.stdout.read())

likelihoodlist = []
bigparamslist = []
smallparamlist = []
aiclist = []
biclist = []

# reading the number of sequences
sequences = 0
fp = open(alignmentName, 'r')
content = fp.readlines()
fp.close()
for line in content:
    if line.startswith('>'):
        sequences = sequences + 1



for i in range(len(AAModels)):
    aa = "PROTGAMMAI" + AAModels[i]
    cmd = raxmlExecutable + " -f e -m " + aa + " -s " + alignmentName + " -t RAxML_parsimonyTree.ST_" \
          + alignmentName + " -n " + AAModels[
              i] + "_" + alignmentName + "_EVAL"  # \> " + AAModels[i] + "_" + alignmentName + "_EVAL.out\n"
    mycmd = Popen(cmd, shell=True, stdout=PIPE)
    myoutput = (mycmd.stdout.read())
    outlines = myoutput.splitlines()

    likelihood=''
    paramsandbranches=''
    paramsnobranch=''

    for line in outlines:
        if (line.startswith('Final GAMMA  likelihood: ')):
            likelihood = float(re.sub(r'.*: ', '', line))
        if (line.startswith('Number of free parameters for AIC-TEST(BR-LEN): ')):
            paramsandbranches = float(re.sub(r'.*: ', '', line))
        if (line.startswith('Number of free parameters for AIC-TEST(NO-BR-LEN): ')):
            paramsnobranch = float(re.sub(r'.*: ', '', line))

    mycmd = Popen('rm -rf *_EVAL ' + alignmentName + '.reduced', shell=True, stdout=PIPE)
    output = (mycmd.stdout.read())

    #print AAModels[i]
    #print likelihood
    #print paramsandbranches
    #print (2 * paramsandbranches - 2 * likelihood)
    #print '-----------'

    if ((likelihood=='')  or (paramsnobranch=='') or (paramsandbranches=='')):
        #sys.stdout.write('there is an error with this log...')
        #time.sleep(5*random.random())
        #raise(myoutput)
        print myoutput

    #sys.stdout.write('here is likelihood: '+str(likelihood))
    #sys.stdout.write('here is paramsandbranches: '+str(paramsandbranches))
    #sys.stdout.write('here is paramsnobranch: '+str(paramsnobranch))

    #time.sleep(5)

    likelihoodlist.append(likelihood)
    bigparamslist.append(paramsandbranches)
    smallparamlist.append(paramsnobranch)
    aiclist.append(2 * paramsandbranches - 2 * likelihood)
    biclist.append(log(sequences) * paramsandbranches - 2 * likelihood)

mycmd = Popen('rm -rf *ST_' + alignmentName, shell=True, stdout=PIPE)
output = (mycmd.stdout.read())
mycmd = Popen('rm temp.fasta', shell=True, stdout=PIPE)
output = (mycmd.stdout.read())

if (criterion == 'aic'):
    crilist = aiclist
elif (criterion == 'bic'):
    crilist = biclist
else:
    crilist = [-1 * lh for lh in likelihoodlist]

bestidx = crilist.index(min(crilist))
print(AAModels[bestidx])

