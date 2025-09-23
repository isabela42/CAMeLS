#!/bin/bash

version="1.0.0"
usage(){
echo "
Written by Isabela Almeida
Based on CASE by Maina Bitar
Created on September 15, 2025
Last modified on September 23, 2025
Version: ${version}

Description: Write and submit PBS jobs for Step 031 of the
CAMeLS pipeline (CRISPR Analysis Method for Library Screens). 

Usage: bash ipda_camels_step031-to-pbs.sh -i "path/to/input/files" -p "PBS stem" -e "email" -m INT -c INT -w "HH:MM:SS"

Resources used for pipeline in-house: -m 20 -c 2 -w "08:00:00"

## Input:

-i <path/to/input/files>    Input TSV files including path FROM working
                            directory. This TSV file should contain:
                            
                            Col1:
                            cell type
                            E.g. FT194

                            Col2:
                            /path/from/working/dir/to/library.fasta

                            Col3:
                            guide-size-INT
                            E.g. 23 for a library with 23nt guides

                            Col4:
                            /path/from/working/dir/to/negative-controls-id.txt

                            Col5:
                            /path/from/working/dir/to/raw/reads/stem-ctrl-day0-rep1*1.f*
                            of R1 file in individual line and no full stops.
                            Warning: Either R1 or R2 could be given as input.
                            However, R1 is tipically used for this analysis.
                            Extensions accepted: .fastq.gz/fq.gz

                            Col6:
                            /path/from/working/dir/to/raw/reads/stem-ctrl-day0-rep2*1.f*
                            of R1 file in individual line and no full stops.
                            Warning: Either R1 or R2 could be given as input.
                            However, R1 is tipically used for this analysis.
                            Extensions accepted: .fastq.gz/fq.gz

                            Col7:
                            /path/from/working/dir/to/raw/reads/stem-ctrl-day0-rep3*1.f*
                            of R1 file in individual line and no full stops.
                            Warning: Either R1 or R2 could be given as input.
                            However, R1 is tipically used for this analysis.
                            Extensions accepted: .fastq.gz/fq.gz

                            Col8:
                            /path/from/working/dir/to/raw/reads/stem-experiment-rep1*1.f*
                            of R1 file in individual line and no full stops.
                            Warning: Either R1 or R2 could be given as input.
                            However, R1 is tipically used for this analysis.
                            Extensions accepted: .fastq.gz/fq.gz

                            Col9:
                            /path/from/working/dir/to/raw/reads/stem-experiment-rep2*1.f*
                            of R1 file in individual line and no full stops.
                            Warning: Either R1 or R2 could be given as input.
                            However, R1 is tipically used for this analysis.
                            Extensions accepted: .fastq.gz/fq.gz

                            Col10:
                            /path/from/working/dir/to/raw/reads/stem-experiment-rep3*1.f*
                            of R1 file in individual line and no full stops.
                            Warning: Either R1 or R2 could be given as input.
                            However, R1 is tipically used for this analysis.
                            Extensions accepted: .fastq.gz/fq.gz

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
#-->030 Count reads from FASTQ files (1MAGeCK - replicate level; 2MAGeCK - combined replicates)
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
        ?) echo script usage: bash ipda_camels_step031-to-pbs.sh -i path/to/input/files -p PBS stem -e email -m INT -c INT -w "HH:MM:SS" >&2
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
logfile=logfile_ipda_camels031-to-pbs_${thislogdate}.txt

#................................................
#  Required modules, softwares and libraries
#................................................

# MAGeCK:
# <https://sourceforge.net/projects/mageck/>
module_mageck="conda-envs/mageck-0.5.9.5"

#................................................
#  Set and create output path
#................................................

## Set stem for output directories
out_path_step031_MAGeCK="camels031_count-reads_MAGeCK_${thislogdate}"

## Create output directories
mkdir -p ${out_path_step031_MAGeCK}

#................................................
#  Print Execution info to user
#................................................

date
echo "## Executing bash ipda_camels_step031-to-pbs.sh"
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
echo "## Output files saved to:       ${out_path_step031_MAGeCK}"
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
echo "## Executing bash ipda_camels_step031-to-pbs.sh"
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
echo "## Output files saved to:       ${out_path_step031_MAGeCK}"
echo "## This is logfile:             ${logfile}"

set -v

#................................................
#  Create PBS files
#................................................

## Write PBS header
cut -f1 ${input} | sort | uniq | while read celltype; do echo "#!/bin/sh" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "##########################################################################" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "#" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "#  Script:  ${pbs_stem}_${celltype}_${thislogdate}.pbs" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "#  Author:  Isabela Almeida" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "#  Created: ${human_thislogdate} at QIMR Berghofer (Brisbane, Australia) - VSC" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "#  Updated: ${human_thislogdate} at QIMR Berghofer (Brisbane, Australia) - VSC" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "#  Version: v01" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "#  Email:   ${email}" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "#" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "##########################################################################" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done

## Write PBS directives
cut -f1 ${input} | sort | uniq | while read celltype; do echo "#PBS -N ${pbs_stem}_${celltype}_${thislogdate}" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "#PBS -r n" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "#PBS -l mem=${mem}GB,walltime=${walltime},ncpus=${ncpus}" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "#PBS -m abe" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "#PBS -M ${email}" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done

## Write directory setting
cut -f1 ${input} | sort | uniq | while read celltype; do echo "#................................................" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "#  Set main working directory" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "#................................................" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "## Change to main directory" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo 'cd ${PBS_O_WORKDIR}' >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo 'echo ; echo "WARNING: The main directory for this run was set to ${PBS_O_WORKDIR}"; echo ' >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done

## Write load modules
cut -f1 ${input} | sort | uniq | while read celltype; do echo "#................................................" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "#  Load Softwares, Libraries and Modules" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "#................................................" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "module load ${module_mageck}" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done

## Write PBS command lines
cut -f1 ${input} | sort | uniq | while read celltype; do echo "#................................................" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "#  Run step" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "#................................................" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo 'echo "## Run MAGeCK with negative control normalization at" ; date ; echo' >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
# Each replicate individually compared with the CTRL (Day 0) in single-end mode at gene level.
cut -f1 ${input} | sort | uniq | while read celltype; do libraryfasta=`grep "${celltype}" ${input} | cut -f2 | sort | uniq`; guidelen=`grep "${celltype}" ${input} | cut -f3 | sort | uniq`; negativectrl=`grep "${celltype}" ${input} | cut -f4 | sort | uniq`; ctrl1=`grep "${celltype}" ${input} | cut -f5 | sort | uniq`; rep1=`grep "${celltype}" ${input} | cut -f8 | sort | uniq`; echo "mageck count --sgrna-len ${guidelen} --control-sgrna ${negativectrl} --norm-method control -l ${libraryfasta} -n ${out_path_step031_MAGeCK}/${celltype}_nctrl-rep1 --sample-label ${celltype}r1,CTRL1 --fastq ${rep1} ${ctrl1}" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do libraryfasta=`grep "${celltype}" ${input} | cut -f2 | sort | uniq`; guidelen=`grep "${celltype}" ${input} | cut -f3 | sort | uniq`; negativectrl=`grep "${celltype}" ${input} | cut -f4 | sort | uniq`; ctrl2=`grep "${celltype}" ${input} | cut -f6 | sort | uniq`; rep2=`grep "${celltype}" ${input} | cut -f9 | sort | uniq`; echo "mageck count --sgrna-len ${guidelen} --control-sgrna ${negativectrl} --norm-method control -l ${libraryfasta} -n ${out_path_step031_MAGeCK}/${celltype}_nctrl-rep2 --sample-label ${celltype}r2,CTRL2 --fastq ${rep2} ${ctrl2}" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do libraryfasta=`grep "${celltype}" ${input} | cut -f2 | sort | uniq`; guidelen=`grep "${celltype}" ${input} | cut -f3 | sort | uniq`; negativectrl=`grep "${celltype}" ${input} | cut -f4 | sort | uniq`; ctrl3=`grep "${celltype}" ${input} | cut -f7 | sort | uniq`; rep3=`grep "${celltype}" ${input} | cut -f10 | sort | uniq`; echo "mageck count --sgrna-len ${guidelen} --control-sgrna ${negativectrl} --norm-method control -l ${libraryfasta} -n ${out_path_step031_MAGeCK}/${celltype}_negCtrol-rep3 --sample-label ${celltype}r3,CTRL3 --fastq ${rep3} ${ctrl3}" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do echo "" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done

cut -f1 ${input} | sort | uniq | while read celltype; do echo 'echo "## Run MAGeCK with median normalization at" ; date ; echo' >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
# Each replicate individually compared with the CTRL (Day 0) in single-end mode at gene level.
cut -f1 ${input} | sort | uniq | while read celltype; do libraryfasta=`grep "${celltype}" ${input} | cut -f2 | sort | uniq`; guidelen=`grep "${celltype}" ${input} | cut -f3 | sort | uniq`; negativectrl=`grep "${celltype}" ${input} | cut -f4 | sort | uniq`; ctrl1=`grep "${celltype}" ${input} | cut -f5 | sort | uniq`; rep1=`grep "${celltype}" ${input} | cut -f8 | sort | uniq`; echo "mageck count --sgrna-len ${guidelen} --norm-method median -l ${libraryfasta} -n ${out_path_step031_MAGeCK}/${celltype}_median-rep1 --sample-label ${celltype}r1,CTRL1 --fastq ${rep1} ${ctrl1}" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do libraryfasta=`grep "${celltype}" ${input} | cut -f2 | sort | uniq`; guidelen=`grep "${celltype}" ${input} | cut -f3 | sort | uniq`; negativectrl=`grep "${celltype}" ${input} | cut -f4 | sort | uniq`; ctrl2=`grep "${celltype}" ${input} | cut -f6 | sort | uniq`; rep2=`grep "${celltype}" ${input} | cut -f9 | sort | uniq`; echo "mageck count --sgrna-len ${guidelen} --norm-method median -l ${libraryfasta} -n ${out_path_step031_MAGeCK}/${celltype}_median-rep2 --sample-label ${celltype}r2,CTRL2 --fastq ${rep2} ${ctrl2}" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read celltype; do libraryfasta=`grep "${celltype}" ${input} | cut -f2 | sort | uniq`; guidelen=`grep "${celltype}" ${input} | cut -f3 | sort | uniq`; negativectrl=`grep "${celltype}" ${input} | cut -f4 | sort | uniq`; ctrl3=`grep "${celltype}" ${input} | cut -f7 | sort | uniq`; rep3=`grep "${celltype}" ${input} | cut -f10 | sort | uniq`; echo "mageck count --sgrna-len ${guidelen} --norm-method median -l ${libraryfasta} -n ${out_path_step031_MAGeCK}/${celltype}_median-rep3 --sample-label ${celltype}r3,CTRL3 --fastq ${rep3} ${ctrl3}" >> ${pbs_stem}_${celltype}_${thislogdate}.pbs; done

#................................................
#  Submit PBS jobs
#................................................

## Submit PBS jobs 
ls ${pbs_stem}_*${thislogdate}.pbs | while read pbs; do echo ; echo "#................................................" ; echo "# This is PBS: ${pbs}" ;  echo "#" ; echo "# main command line(s): $(tail -n8 ${pbs} | head -n1)" ; echo "#                       $(tail -n7 ${pbs} | head -n1)" ; echo "#                       $(tail -n6 ${pbs} | head -n1)" ; echo "#                       $(tail -n3 ${pbs} | head -n1)" ; echo "#                       $(tail -n2 ${pbs} | head -n1)" ; echo "#                       $(tail -n1 ${pbs})" ; echo "#" ; echo "# now submitting PBS" ; echo "qsub ${pbs}" ; qsub ${pbs} ; echo "#................................................" ; done

date ## Status of all user jobs (including CAMeLS step 031 jobs) at
qstat -u "$user"

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
sed -i 's,${out_path_step031_MAGeCK},'"${out_path_step031_MAGeCK}"',g' "$logfile"
sed -i 's,${logfile},'"${logfile}"',g' "$logfile"
sed -n -e :a -e '1,3!{P;N;D;};N;ba' $logfile > tmp ; mv tmp $logfile
set +v