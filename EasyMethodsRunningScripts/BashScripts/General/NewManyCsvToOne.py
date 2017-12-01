import argparse
import pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument('-i', '--input', type=str, default='BaliPhy-PD.csv,Mafft.csv,BaliPhy-MAP.csv',
                    help='Name of csv input files.')
parser.add_argument('-o', '--averageoutput', type=str, default='Average.csv', help='Name of Average csv output file.')
parser.add_argument('-u', '--dataoutput', type=str, default='testdata.csv', help='Name of Data csv output file.(Leave it to None if you dont want it)')
args = parser.parse_args()

statfiles = args.input
avgoutfile = args.averageoutput
dataoutfile=args.dataoutput
statfiles = statfiles.split(',')

aggregateddf=pd.DataFrame()
for statfile in statfiles:
    currdf=pd.read_csv(statfile,index_col=False)
    currdf=currdf.rename(columns={'Unnamed: 0':'Statistics'})
    currdf = currdf.set_index('Statistics').T
    currdf['Dataset']=currdf.index
    currdf.columns.name = None
    currdf.reset_index(drop=True,inplace=True)

    currdf['Method'] = statfile.split('/')[-1].split('.csv')[0]
    aggregateddf=aggregateddf.append(currdf,ignore_index=True)

cols=aggregateddf.columns.tolist()
cols=cols[-2:]+cols[:-2]
aggregateddf=aggregateddf[cols]
if not(dataoutfile=='None'):
    aggregateddf.to_csv(dataoutfile,index=False)

averagedf=aggregateddf.groupby(['Method']).mean()
averagedf.columns.name = None
averagedf['Method']=averagedf.index
averagedf.reset_index(drop=True,inplace=True)

cols=averagedf.columns.tolist()
cols=cols[-1:]+cols[:-1]
averagedf=averagedf[cols]

averagedf.to_csv(avgoutfile,index=False)
