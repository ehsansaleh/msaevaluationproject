This folder is a sample script for running BAliPhy on an HPC Platform such as the BlueWaters.

Here is a simplistic view of the chain of calls.

User --> LoginNode-JobSubmission.sh --> MomNode-Controller.pbs --> ComputationNode-Runner.sh

Here is a short description of what the files are doing:

1) LoginNode-JobSubmission.sh:
    This script prepares the job configurations that are necessary for running multiple instances of BAliPhy on each computation node.
    Each set of sequences (i.e. dataset), needs to have multiple and independent runnings of BAliPhy (let's assume that this number of needed independent runnings of BAliPhy per dataset is x).
    Each job has access to a mult-core processor that can run multiple processes efficiently (let's assume that this number of processes on each core is y).
    Therefore, each job should run z=x/y different datasets.
    The "LoginNode-JobSubmission.sh" script handles running multiple datasets on each node, and generates the related configuration files
    so that the submitted jobs can run BAliPhy for all of the datasets on each benchmark.
    This script runs on the login nodes, reads the protein substituition models from the csv file provided in the location of the benchmark datasets,
    and just submits the jobs through the PBS/qsub 

2) MomNode-Controller.pbs:
    This script just runs the "ComputationNode-Runner.sh" script multiple times using aprun (i.e. a replacement for mpirun).
    
3) ComputationNode-Runner.sh
    This script takes as an argument the number of configurations file.
    Then it reads the config file, and for each line of the file it creates a new process.
    These processes are the actual instances of running BaliPhy.
