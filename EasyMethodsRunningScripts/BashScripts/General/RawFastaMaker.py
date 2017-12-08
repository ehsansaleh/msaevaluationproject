#/usr/local/python/2.7.11/bin/python
import os,argparse
os.sys.path.append('/projects/tallis/ehsan/MikeUtilities/')
import alignment_utils as au
import shutil

parser=argparse.ArgumentParser()
parser.add_argument('-i','--input_folder',type=str,default='input',help='Name of input aligned fasta file.')
parser.add_argument('-o','--out_folder',type=str,default='output',help='Name of output raw fasta file.')
args=parser.parse_args()

inputFolder=args.input_folder
outputFolder=args.out_folder

if not os.path.exists(inputFolder):
    raise('Input Folder does not exist...')

#if os.path.exists(outputFolder):
#    shutil.rmtree(outputFolder)
if not os.path.exists(outputFolder):
    os.makedirs(outputFolder)

if not(inputFolder[-1]=='/'):
    inputFolder=inputFolder+'/'
if not(outputFolder[-1]=='/'):
    outputFolder=outputFolder+'/'

for root, dirs, files in os.walk(inputFolder):
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
            if os.path.exists(outputFolder + fastaname + extension):
                continue

            fastaFile = str(os.path.join(root, file))
            FullFasta = au.read_from_fasta(fastaFile)
            au.write_to_fasta(out_file_path=outputFolder + fastaname + extension, fasta_dict=FullFasta, raw=True)
