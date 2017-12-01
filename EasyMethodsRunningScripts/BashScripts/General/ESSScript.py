import argparse,os
import pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument('-i', '--input', type=str, default='/projects/tallis/ehsan/Studies/MafftVsBaliphy/ProcessedData/BPAnalyzeResults/AminoAcids/MattBench', help='Full path of input database folder.')
parser.add_argument('-o', '--output', type=str, default='out.csv', help='Output csv file.')
args = parser.parse_args()

inputfolder = args.input
outcsv=args.output
if inputfolder[-1]=='/':
    inputfolder=inputfolder[:-1]

def valextractor(reportpath):
    miness='NaN'
    minburnin='NaN'
    maxPSRF80CI='NaN'
    maxPSRFRCF = 'NaN'
    with open(reportpath, 'r') as f:
        lines = f.read().splitlines()
    f.close()

    minstat=''
    for line in lines:
        linelist=line.split()
        if len(linelist)>2:
            if linelist[0]=='Ne' and linelist[1]=='>=':
                minstat=linelist[-1].split('(')[-1].split(')')[0]

    if not minstat=='':
        for i,line in enumerate(lines):
            linelist = line.split()
            if len(linelist)>2:
                if linelist[0]==minstat and linelist[1]=='~':
                    minline=i+1
                    break

        minessline=lines[minline]
        minesslinelist=minessline.split()
        if 'Ne' in minesslinelist:
            if minesslinelist.index('Ne') + 1 < len(minesslinelist):
                if minesslinelist[minesslinelist.index('Ne')+1]=='=':
                    miness=float(minesslinelist[minesslinelist.index('Ne') + 2])

#Recognizing minimum burnin
    minstat = ''
    for line in lines:
        linelist=line.split()
        if len(linelist)>3:
            if linelist[0]=='min' and linelist[1]=='burnin' and linelist[2]=='<=' :
                minstat=linelist[-1].split('(')[-1].split(')')[0]
    if not minstat == '':
        for i,line in enumerate(lines):
            linelist = line.split()
            if len(linelist)>2:
                if linelist[0]==minstat and linelist[1]=='~':
                    minline=i+1
                    break

        minburnline=lines[minline]
        minesslinelist=minburnline.split()
        if 'burnin' in minesslinelist:
            if minesslinelist.index('burnin') + 1 < len(minesslinelist):
                if minesslinelist[minesslinelist.index('burnin')+1]=='=':
                    try:
                        minburnin=float(minesslinelist[minesslinelist.index('burnin') + 2])
                    except:
                        if minesslinelist[minesslinelist.index('burnin') + 2]=='Not':
                            minburnin='Not Converged!'

#Recognizing maximum PSRF-80%CI
    minstat = ''
    for line in lines:
        linelist=line.split()
        if len(linelist)>2:
            if linelist[0]=='PSRF-80%CI' and linelist[1]=='<=' :
                minstat=linelist[-1].split('(')[-1].split(')')[0]
    if not minstat == '':
        for i,line in enumerate(lines):
            linelist = line.split()
            if len(linelist)>2:
                if linelist[0]==minstat and linelist[1]=='~':
                    minline=i+2
                    break

        minburnline=lines[minline]
        minesslinelist=minburnline.split()
        if 'PSRF-80%CI' in minesslinelist:
            if minesslinelist.index('PSRF-80%CI') + 1 < len(minesslinelist):
                if minesslinelist[minesslinelist.index('PSRF-80%CI')+1]=='=':
                    maxPSRF80CI=float(minesslinelist[minesslinelist.index('PSRF-80%CI') + 2])

#Recognizing maximum PSRF-RCF
    minstat = ''
    for line in lines:
        linelist=line.split()
        if len(linelist)>2:
            if linelist[0]=='PSRF-RCF' and linelist[1]=='<=' :
                minstat=linelist[-1].split('(')[-1].split(')')[0]

    if not minstat == '':
        for i,line in enumerate(lines):
            linelist = line.split()
            if len(linelist)>2:
                if linelist[0]==minstat and linelist[1]=='~':
                    minline=i+2
                    break

        minburnline=lines[minline]
        minesslinelist=minburnline.split()
        if 'PSRF-RCF' in minesslinelist:
            if minesslinelist.index('PSRF-RCF') + 1 < len(minesslinelist):
                if minesslinelist[minesslinelist.index('PSRF-RCF')+1]=='=':
                    maxPSRFRCF=float(minesslinelist[minesslinelist.index('PSRF-RCF') + 2])

    return miness,minburnin,maxPSRF80CI,maxPSRFRCF

df = pd.DataFrame()
for mydir in  os.listdir(inputfolder):
    miness = 'NaN'
    minburnin = 'NaN'
    maxPSRF80CI = 'NaN'
    maxPSRFRCF = 'NaN'
    print mydir
    for root, dirs, files in os.walk(inputfolder+'/'+mydir):
        for file in files:
            if file=='Report':
                fileadress=os.path.join(root, file)
                miness, minburnin, maxPSRF80CI, maxPSRFRCF=valextractor(fileadress)

    df = df.append({'Dataset': mydir,
                    'Database': inputfolder.split('/')[-1],
                    'Minimum ESS':miness,
                    'Maximal Minmimum Burnin':minburnin,
                    'Maximum PSRF-80%CI':maxPSRF80CI,
                    'Maximum PSRF-RCF':maxPSRFRCF}, ignore_index=True)

df.to_csv(outcsv,index=False)