#!/usr/local/python/2.7.11/bin/python
import sys,os,shutil,argparse
sys.path.append('/projects/tallis/ehsan/MikeUtilities/')
import alignment_utils as au

#This script does not convert the taxa name in trees. It only converts names in fasta files
parser=argparse.ArgumentParser()
parser.add_argument('-i','--input_folder',type=str,default='input',help='Name of input datasets folder.(Please only input relative path'
                                                                        ' to the code directory such as input)')
parser.add_argument('-r','--relativity',action="store_true",help='Relativity of addresses, Please set this flag if you are passing full paths for input or output.'
                                                                 'Otherwise please enter relative paths to the code directory.')
parser.add_argument('-o','--output_folder',type=str,default='output',help='Name of output datasets folder.')
args=parser.parse_args()

inFolder=args.input_folder
outFolder=args.output_folder
fulllyPath=args.relativity

harnessing=False     #Harnessing the sequences with just one letter. Only needed for gutell seed alignments
ScriptPath=os.getcwd()

if not(fulllyPath):
    inFolder=ScriptPath+'/'+inFolder
    outFolder=ScriptPath+'/'+outFolder

if not(inFolder[-1]=='/'):
    inFolder = inFolder + '/'
if not(outFolder[-1]=='/'):
    outFolder = outFolder + '/'



#if os.path.exists(outFolder):
#    shutil.rmtree(outFolder)
if not os.path.exists(outFolder):
    os.makedirs(outFolder)

def mynum2string(count):
    countstring = ''
    while count:
        ones = count % 26
        count = count / 26
        newletter = chr(65 + ones)
        countstring = newletter + countstring
    for i in range(10 - len(countstring)):
        countstring = 'A' + countstring
    return countstring

for root, dirs, files in os.walk(inFolder):
    for file in files:
        if file.endswith('.fasta') or file.endswith('.fna') or file.endswith('.faa'):

            if file.endswith('.fasta'):
                extension='.fasta'
                fastaname = file[0:-6]
            if file.endswith('.fna'):
                extension='.fna'
                fastaname = file[0:-4]
            if file.endswith('.faa'):
                extension='.faa'
                fastaname = file[0:-4]
            if os.path.exists(outFolder+ fastaname + extension):
                continue
            #print 'reached here'
	    #print outFolder+ fastaname + extension
            #exit(0)

            fastaFile = str(os.path.join(root, file))

            FullFasta = au.read_from_fasta(fastaFile)

            print('Processing Dataset ' + fastaname)
            unharnessedlength=len(FullFasta[FullFasta.keys()[0]])
            if(harnessing):
                print('Number of unharnessed sequences was '+str(len(FullFasta)))
                for taxon in FullFasta.keys():
                    rawseq = FullFasta[taxon].replace("-", "")
                    if len(rawseq)<0.1*unharnessedlength:
                        FullFasta.pop(taxon)
                print('After harnessing, number of sequences became ' + str(len(FullFasta)))

            #Removing blank columns
            blankcollist=[]
            print('Preprocessed number of columns is '+ str(len(FullFasta[FullFasta.keys()[0]])))
            for col in range(len(FullFasta[FullFasta.keys()[0]])):
                blank=True
                for taxon in FullFasta.keys():
                    if not(FullFasta[taxon][col]=='-' or FullFasta[taxon][col]=='x'):
                        blank=False
                if (blank):
                    blankcollist.append(col)
            for taxon in FullFasta.keys():
                newstring = list(FullFasta[taxon])
                for col in blankcollist:
                    newstring[col]='='
                FullFasta[taxon]="".join(newstring).replace("=", "")
            print('Final number of columns is ' + str(len(FullFasta[FullFasta.keys()[0]])))

            count=0
            namemappingdict={}
            for taxon in FullFasta.keys():
                simplename=mynum2string(count)
                namemappingdict[taxon]=simplename
                FullFasta[simplename] = FullFasta.pop(taxon)
                count=count+1
            #print(FullFasta.keys())
            #print(namemappingdict)
            au.write_to_fasta(out_file_path=outFolder+ fastaname + extension, fasta_dict=FullFasta, raw=False)
            target = open(outFolder+ fastaname+'.name_map', 'w')
            for complicatedname in namemappingdict.keys():
                target.write(complicatedname + ' ' + namemappingdict[complicatedname] +'\n')
            target.close()
            print('----------')
            print('')
