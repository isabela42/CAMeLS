#!/bin/bash

version="1.0.0"
usage(){
echo "
Written by Isabela Almeida
Based on CASE by Maina Bitar
Created on September 24, 2025
Last modified on September 24, 2025
Version: ${version}

Description: Write and submit PBS jobs for Step 033 of the
CAMeLS pipeline (CRISPR Analysis Method for Library Screens). 

Usage: bash ipda_camels_step033-to-pbs.sh -i "path/to/input/files" -p "PBS stem" -e "email" -m INT -c INT -w "HH:MM:SS"

Resources used for pipeline in-house: -m 1 -c 1 -w "01:00:00"

## Input:

-i <path/to/input/files>    Input TSV files including path FROM working
                            directory. This TSV file should contain:
                            
                            Col1:
                            /path/from/working/dir/to/pbs-error-file.e####

                            Col2:
                            cell type
                            E.g. FT194

                            Col3:
                            /path/from/working/dir/to/raw/reads/stem-ctrl-day0-rep1*1.f*
                            of R1 file in individual line and no full stops.
                            Warning: Either R1 or R2 could be given as input.
                            However, R1 is tipically used for this analysis.
                            Extensions accepted: .fastq.gz/fq.gz

                            Col4:
                            /path/from/working/dir/to/raw/reads/stem-ctrl-day0-rep2*1.f*
                            of R1 file in individual line and no full stops.
                            Warning: Either R1 or R2 could be given as input.
                            However, R1 is tipically used for this analysis.
                            Extensions accepted: .fastq.gz/fq.gz

                            Col5:
                            /path/from/working/dir/to/raw/reads/stem-ctrl-day0-rep3*1.f*
                            of R1 file in individual line and no full stops.
                            Warning: Either R1 or R2 could be given as input.
                            However, R1 is tipically used for this analysis.
                            Extensions accepted: .fastq.gz/fq.gz

                            Col6:
                            /path/from/working/dir/to/raw/reads/stem-experiment-rep1*1.f*
                            of R1 file in individual line and no full stops.
                            Warning: Either R1 or R2 could be given as input.
                            However, R1 is tipically used for this analysis.
                            Extensions accepted: .fastq.gz/fq.gz

                            Col7:
                            /path/from/working/dir/to/raw/reads/stem-experiment-rep2*1.f*
                            of R1 file in individual line and no full stops.
                            Warning: Either R1 or R2 could be given as input.
                            However, R1 is tipically used for this analysis.
                            Extensions accepted: .fastq.gz/fq.gz

                            Col8:
                            /path/from/working/dir/to/raw/reads/stem-experiment-rep3*1.f*
                            of R1 file in individual line and no full stops.
                            Warning: Either R1 or R2 could be given as input.
                            However, R1 is tipically used for this analysis.
                            Extensions accepted: .fastq.gz/fq.gz

                            Col9:
                            library-stem

                            It does not matter if same stem 
                            appears more than once on this input file.

-p <PBS stem>               Stem for PBS file names
-e <email>                  Email for PBS job
-m <INT>                    Memory INT required for PBS job in GB
-c <INT>                    Number of CPUS required for PBS job
-w <HH:MM:SS>               Clock walltime required for PBS job

## Output:

logfile.txt                 Logfile with commands executed and date
PBS files                   PBS files created

Pipeline description:

#   010 Quality check sequencing (1FastQC, 2MultiQC)
#   020 Plasmid-representation (1BBDuk - finds 23nt perfect matchs and 21nt 0,2 and 3MM, 2BASH - write to TSV)
#-->030 Count reads from FASTQ files (1MAGeCK - replicate level; 2MAGeCK - combined replicates; 3Bash - summary)
#   040 Statistical test (1MAGeCK)
#   050 Plot results (1MAGeCK)

Please contact Isabela Almeida at mb.isabela42@gmail.com if you encounter any problems.
"
}

## Display help message
if [ -z "$1" ] || [[ $1 == -h ]] || [[ $1 == --help ]]; then
	usage
	exit
fi

#  ____       _   _   _                 
# / ___|  ___| |_| |_(_)_ __   __ _ ___ 
# \___ \ / _ \ __| __| | '_ \ / _` / __|
#  ___) |  __/ |_| |_| | | | | (_| \__ \
# |____/ \___|\__|\__|_|_| |_|\__, |___/
#                             |___/     

## Save execution ID
pid=`echo $$` #$BASHPID

## User name within your cluster environment
user=`whoami`

## Exit when any command fails
set -e

#................................................
#  Input parameters from command line
#................................................

## Get parameters from command line flags
while getopts "i:p:e:m:c:w:h:v" flag
do
    case "${flag}" in
        i) input="${OPTARG}";;       # Input files including path
        p) pbs_stem="${OPTARG}";;    # Stem for PBS file names
        e) email="${OPTARG}";;       # Email for PBS job
        m) mem="${OPTARG}";;         # Memory required for PBS job
        c) ncpus="${OPTARG}";;       # Number of CPUS required for PBS job
        w) walltime="${OPTARG}";;    # Clock walltime required for PBS job
        h) Help ; exit;;             # Print Help and exit
        v) echo "${version}"; exit;; # Print version and exit
        ?) echo script usage: bash ipda_camels_step033-to-pbs.sh -i path/to/input/files -p PBS stem -e email -m INT -c INT -w "HH:MM:SS" >&2
           exit;;
    esac
done

#................................................
#  Set Logfile stem
#................................................

## Set Logfile stem
# it contains all the executed commands with date/time;
# the output files general metrics (such as size);
# and memory/CPU usage for all executions
thislogdate=$(date +'%d%m%Y%H%M%S%Z')
human_thislogdate=`date`
logfile=logfile_ipda_camels033-to-pbs_${thislogdate}.txt

#................................................
#  Set and create output path
#................................................

## Set stem for output directories
out_path_step033_summary="camels033_count-reads_summary_${thislogdate}"

## Create output directories
mkdir -p ${out_path_step033_summary}

#................................................
#  Print Execution info to user
#................................................

date
echo "## Executing bash ipda_camels_step033-to-pbs.sh"
echo "## This execution PID: ${pid}"
echo
echo "## Given inputs:"
echo
echo "## Input files:                 ${input}"
echo "## PBS stem:                    ${pbs_stem}"
echo "## Email for PBS notifications: ${email}"
echo "## PBS job memory required:     ${mem}"
echo "## PBS job NCPUS required:      ${ncpus}"
echo "## PBS job walltime required:   ${walltime}"
echo
echo "## Outputs created:"
echo
echo "## Output files saved to:       ${out_path_step033_summary}"
echo "## logfile will be saved as:    ${logfile}"
echo

# ____  _             _   _                   
#/ ___|| |_ __ _ _ __| |_(_)_ __   __ _       
#\___ \| __/ _` | '__| __| | '_ \ / _` |      
# ___) | || (_| | |  | |_| | | | | (_| |_ _ _ 
#|____/ \__\__,_|_|   \__|_|_| |_|\__, (_|_|_)
#                                 |___/  

#................................................
#  Print Execution info to logfile
#................................................

exec &> "${logfile}"

date
echo "## Executing bash ipda_camels_step033-to-pbs.sh"
echo "## This execution PID: ${pid}"
echo
echo "## Given inputs:"
echo
echo "## Input files:                 ${input}"
echo "## PBS stem:                    ${pbs_stem}"
echo "## Email for PBS notifications: ${email}"
echo "## PBS job memory required:     ${mem}"
echo "## PBS job NCPUS required:      ${ncpus}"
echo "## PBS job walltime required:   ${walltime}"
echo
echo "## Outputs created:"
echo
echo "## Output files saved to:       ${out_path_step033_summary}"
echo "## This is logfile:             ${logfile}"

set -v

#................................................
#  Summary of count reads
#................................................

date ## Collect run summary for step 030 at
cut -f1 ${input} | sort | uniq | while read file; do library=`grep "${file}" ${input} | cut -f9 | sort | uniq`; celltype=`grep "${file}" ${input} | cut -f2 | sort | uniq`; ctrl1=`grep "${celltype}" ${input} | cut -f3 | sort | uniq`; ctrl2=`grep "${celltype}" ${input} | cut -f4 | sort | uniq`; ctrl3=`grep "${celltype}" ${input} | cut -f5 | sort | uniq`; rep1=`grep "${celltype}" ${input} | cut -f6 | sort | uniq`; rep2=`grep "${celltype}" ${input} | cut -f7 | sort | uniq`; rep3=`grep "${celltype}" ${input} | cut -f8 | sort | uniq`; 

# get metrics from replicate 1 (experiment and control)
pnc1=`grep "Parameters:.*-n camels031_count-reads_MAGeCK_.*/${celltype}_nctrl-rep1" ${file} | cut -d':' -f5- | uniq`;
pmedian1=`grep "Parameters:.*-n camels031_count-reads_MAGeCK_.*/${celltype}_median-rep1" ${file} | cut -d':' -f5- | uniq`;
len=`grep "Determining the trim-5" ${file} | grep 'Possible gRNA lengths' | cut -d':' -f5 | sort | uniq | tr '\n' ';' | sed 's/.$//'`;
labelexp1=`grep -A1 "Summary of file.*${rep1}" | cut -d':' -f4- | sort | uniq | grep 'label' | tr ' ' '\t' | cut -f3`; 
readsexp1=`grep -A2 "Summary of file.*${rep1}" | cut -d':' -f4- | sort | uniq | grep 'reads' | tr ' ' '\t' | cut -f3`;
mappedreadsexp1=`grep -A13"Summary of file.*${rep1}" | cut -d':' -f4- | sort | uniq | grep 'mappedreads' | tr ' ' '\t' | cut -f3`;
totalsgrnasexp1=`grep -A4 "Summary of file.*${rep1}" | cut -d':' -f4- | sort | uniq | grep 'totalsgrnas' | tr ' ' '\t' | cut -f3`;
labelctrl1=`grep -A1 "Summary of file.*${ctrl1}" | cut -d':' -f4- | sort | uniq | grep 'label' | tr ' ' '\t' | cut -f3`; 
readsctrl1=`grep -A2 "Summary of file.*${ctrl1}" | cut -d':' -f4- | sort | uniq | grep 'reads' | tr ' ' '\t' | cut -f3`;
mappedreadsctrl1=`grep -A13"Summary of file.*${ctrl1}" | cut -d':' -f4- | sort | uniq | grep 'mappedreads' | tr ' ' '\t' | cut -f3`;
totalsgrnasctrl1=`grep -A4 "Summary of file.*${ctrl1}" | cut -d':' -f4- | sort | uniq | grep 'totalsgrnas' | tr ' ' '\t' | cut -f3`;
vectorsizenc1=`grep -B1 "Parameters:.*-n camels031_count-reads_MAGeCK_.*/${celltype}_nctrl-rep1\|Summary of file.*${rep1}" ${file} | grep -A2 "Parameters:.*-n camels031_count-reads_MAGeCK_.*/${celltype}_nctrl-rep1" | cut -d':' -f5`;
vectorsizemedian1=`grep -B1 "Parameters:.*-n camels031_count-reads_MAGeCK_.*/${celltype}_median-rep1\|Summary of file.*${rep1}" ${file} | grep -A2 "Parameters:.*-n camels031_count-reads_MAGeCK_.*/${celltype}_median-rep1" | cut -d':' -f5`;

# get metrics from replicate 2 (experiment and control)
pnc2=`grep "Parameters:.*-n camels031_count-reads_MAGeCK_.*/${celltype}_nctrl-rep2" ${file} | cut -d':' -f5- | uniq`;
pmedian2=`grep "Parameters:.*-n camels031_count-reads_MAGeCK_.*/${celltype}_median-rep2" ${file} | cut -d':' -f5- | uniq`;
len=`grep "Determining the trim-5" ${file} | grep 'Possible gRNA lengths' | cut -d':' -f5 | sort | uniq | tr '\n' ';' | sed 's/.$//'`;
labelexp2=`grep -A1 "Summary of file.*${rep2}" | cut -d':' -f4- | sort | uniq | grep 'label' | tr ' ' '\t' | cut -f3`; 
readsexp2=`grep -A2 "Summary of file.*${rep2}" | cut -d':' -f4- | sort | uniq | grep 'reads' | tr ' ' '\t' | cut -f3`;
mappedreadsexp2=`grep -A13"Summary of file.*${rep2}" | cut -d':' -f4- | sort | uniq | grep 'mappedreads' | tr ' ' '\t' | cut -f3`;
totalsgrnasexp2=`grep -A4 "Summary of file.*${rep2}" | cut -d':' -f4- | sort | uniq | grep 'totalsgrnas' | tr ' ' '\t' | cut -f3`;
labelctrl2=`grep -A1 "Summary of file.*${ctrl2}" | cut -d':' -f4- | sort | uniq | grep 'label' | tr ' ' '\t' | cut -f3`; 
readsctrl2=`grep -A2 "Summary of file.*${ctrl2}" | cut -d':' -f4- | sort | uniq | grep 'reads' | tr ' ' '\t' | cut -f3`;
mappedreadsctrl2=`grep -A13"Summary of file.*${ctrl2}" | cut -d':' -f4- | sort | uniq | grep 'mappedreads' | tr ' ' '\t' | cut -f3`;
totalsgrnasctrl2=`grep -A4 "Summary of file.*${ctrl2}" | cut -d':' -f4- | sort | uniq | grep 'totalsgrnas' | tr ' ' '\t' | cut -f3`;
vectorsizenc2=`grep -B1 "Parameters:.*-n camels031_count-reads_MAGeCK_.*/${celltype}_nctrl-rep2\|Summary of file.*${rep2}" ${file} | grep -A2 "Parameters:.*-n camels031_count-reads_MAGeCK_.*/${celltype}_nctrl-rep2" | cut -d':' -f5`;
vectorsizemedian2=`grep -B1 "Parameters:.*-n camels031_count-reads_MAGeCK_.*/${celltype}_median-rep2\|Summary of file.*${rep2}" ${file} | grep -A2 "Parameters:.*-n camels031_count-reads_MAGeCK_.*/${celltype}_median-rep2" | cut -d':' -f5`;

# get metrics from replicate 3 (experiment and control)
pnc3=`grep "Parameters:.*-n camels031_count-reads_MAGeCK_.*/${celltype}_nctrl-rep3" ${file} | cut -d':' -f5- | uniq`;
pmedian3=`grep "Parameters:.*-n camels031_count-reads_MAGeCK_.*/${celltype}_median-rep3" ${file} | cut -d':' -f5- | uniq`;
len=`grep "Determining the trim-5" ${file} | grep 'Possible gRNA lengths' | cut -d':' -f5 | sort | uniq | tr '\n' ';' | sed 's/.$//'`;
labelexp3=`grep -A1 "Summary of file.*${rep3}" | cut -d':' -f4- | sort | uniq | grep 'label' | tr ' ' '\t' | cut -f3`; 
readsexp3=`grep -A2 "Summary of file.*${rep3}" | cut -d':' -f4- | sort | uniq | grep 'reads' | tr ' ' '\t' | cut -f3`;
mappedreadsexp3=`grep -A13"Summary of file.*${rep3}" | cut -d':' -f4- | sort | uniq | grep 'mappedreads' | tr ' ' '\t' | cut -f3`;
totalsgrnasexp3=`grep -A4 "Summary of file.*${rep3}" | cut -d':' -f4- | sort | uniq | grep 'totalsgrnas' | tr ' ' '\t' | cut -f3`;
labelctrl3=`grep -A1 "Summary of file.*${ctrl3}" | cut -d':' -f4- | sort | uniq | grep 'label' | tr ' ' '\t' | cut -f3`; 
readsctrl3=`grep -A2 "Summary of file.*${ctrl3}" | cut -d':' -f4- | sort | uniq | grep 'reads' | tr ' ' '\t' | cut -f3`;
mappedreadsctrl3=`grep -A13"Summary of file.*${ctrl3}" | cut -d':' -f4- | sort | uniq | grep 'mappedreads' | tr ' ' '\t' | cut -f3`;
totalsgrnasctrl3=`grep -A4 "Summary of file.*${ctrl3}" | cut -d':' -f4- | sort | uniq | grep 'totalsgrnas' | tr ' ' '\t' | cut -f3`;
vectorsizenc3=`grep -B1 "Parameters:.*-n camels031_count-reads_MAGeCK_.*/${celltype}_nctrl-rep3\|Summary of file.*${rep3}" ${file} | grep -A2 "Parameters:.*-n camels031_count-reads_MAGeCK_.*/${celltype}_nctrl-rep3" | cut -d':' -f5`;
vectorsizemedian3=`grep -B1 "Parameters:.*-n camels031_count-reads_MAGeCK_.*/${celltype}_median-rep3\|Summary of file.*${rep3}" ${file} | grep -A2 "Parameters:.*-n camels031_count-reads_MAGeCK_.*/${celltype}_median-rep3" | cut -d':' -f5`;

# write to TSV file
echo -e "${library}\t${celltype}\t${pnc1}\t${len}\t${labelexp1}\t${readsexp1}\t${mappedreadsexp1}\t${totalsgrnasexp1}\t${labelctrl1}\t${readsctrl1}\t${mappedreadsctrl1}\t${totalsgrnasctrl1}\t${vectorsizenc1}\n${library}\t${celltype}\t${pmedian1}\t${len}\t${labelexp1}\t${readsexp1}\t${mappedreadsexp1}\t${totalsgrnasexp1}\t${labelctrl1}\t${readsctrl1}\t${mappedreadsctrl1}\t${totalsgrnasctrl1}\t${vectorsizemedian1}\n${library}\t${celltype}\t${pnc2}\t${len}\t${labelexp2}\t${readsexp2}\t${mappedreadsexp2}\t${totalsgrnasexp2}\t${labelctrl2}\t${readsctrl2}\t${mappedreadsctrl2}\t${totalsgrnasctrl2}\t${vectorsizenc2}\n${library}\t${celltype}\t${pmedian2}\t${len}\t${labelexp2}\t${readsexp2}\t${mappedreadsexp2}\t${totalsgrnasexp2}\t${labelctrl2}\t${readsctrl2}\t${mappedreadsctrl2}\t${totalsgrnasctrl2}\t${vectorsizemedian2}\n${library}\t${celltype}\t${pnc1}\t${len}\t${labelexp3}\t${readsexp3}\t${mappedreadsexp3}\t${totalsgrnasexp3}\t${labelctrl3}\t${readsctrl3}\t${mappedreadsctrl3}\t${totalsgrnasctrl3}\t${vectorsizenc3}\n${library}\t${celltype}\t${pmedian1}\t${len}\t${labelexp3}\t${readsexp3}\t${mappedreadsexp3}\t${totalsgrnasexp3}\t${labelctrl3}\t${readsctrl3}\t${mappedreadsctrl3}\t${totalsgrnasctrl3}\t${vectorsizemedian3}" ${out_path_step033_summary}/summary_${library}-${celltype}.tsv ; done

# This will remove $VARNAMES from output file with the actual $VARVALUE
# allowing for easily retracing commands
sed -i 's,${input},'"${input}"',g' "$logfile"
sed -i 's,${pbs_stem},'"${pbs_stem}"',g' "$logfile"
sed -i 's,${email},'"${email}"',g' "$logfile"
sed -i 's,${mem},'"${mem}"',g' "$logfile"
sed -i 's,${ncpus},'"${ncpus}"',g' "$logfile"
sed -i 's,${walltime},'"${walltime}"',g' "$logfile"
sed -i 's,${human_thislogdate},'"${human_thislogdate}"',g' "$logfile"
sed -i 's,${thislogdate},'"${thislogdate}"',g' "$logfile"
sed -i 's,${user},'"${user}"',g' "$logfile"
sed -i 's,${module_mageck},'"${module_mageck}"',g' "$logfile"
sed -i 's,${out_path_step033_summary},'"${out_path_step033_summary}"',g' "$logfile"
sed -i 's,${logfile},'"${logfile}"',g' "$logfile"
sed -n -e :a -e '1,3!{P;N;D;};N;ba' $logfile > tmp ; mv tmp $logfile
set +v