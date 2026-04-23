#!/bin/bash

version="1.0.0"
usage(){
echo "
Written by Isabela Almeida
Created on Sep 15, 2025
Last modified on Apr 23, 2026
Version: ${version}

Description: Write and submit PBS jobs for Step 033 of the
CAMeLS pipeline (CRISPR Analysis Method for Library Screens). 

Usage: bash ipda_camels_step033-to-pbs.sh -i "path/to/input/files" -p "PBS stem" -e "email" -m INT -c INT -w "HH:MM:SS"

Resources used for pipeline in-house: -m 1 -c 1 -w "00:30:00"

## Input:

-i <path/to/input/files>    Input TSV files including path FROM working
                            directory. This TSV file should contain:
                            
                            Col1:
                            stem-library-name

                            Col2:
                            /path/from/working/dir/to/camels031_counts-replicates_MAGeCK_DATE/stem-rep1.count.txt

                            Col3:
                            /path/from/working/dir/to/camels031_counts-replicates_MAGeCK_DATE/stem-rep2.count.txt

                            Col4:
                            /path/from/working/dir/to/camels031_counts-replicates_MAGeCK_DATE/stem-rep3.count.txt

                            Col5:
                            /path/from/working/dir/to/camels031_counts-replicates_MAGeCK_DATE/stem-rep1.count_normalized.txt

                            Col6:
                            /path/from/working/dir/to/camels031_counts-replicates_MAGeCK_DATE/stem-rep2.count_normalized.txt

                            Col7:
                            /path/from/working/dir/to/camels031_counts-replicates_MAGeCK_DATE/stem-rep3.count_normalized.txt

                            Col8:
                            /path/from/working/dir/to/library.fasta

                            Col9:
                            /path/from/working/dir/to/CAMeLS/scripts/ipda_camels_step030.r

                            Col10:
                            /path/from/working/dir/to/CAMeLS/scripts/ipda_camels_rfunctions.r

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
#-->020 Guide representation (1BBDuk - finds 23nt perfect matchs and 21nt 0,2 and 3MM, 2BASH - write to TSV, 3R plot results)
#   030 Count reads from FASTQ files (1MAGeCK - replicate level; 2MAGeCK - combined replicates; 3Bash - summary replicates; 4Bash - summary combined)
#   040 Statistical test (1MAGeCK; 2Bash summary)
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
out_path_step033_summary="camels033_replicate-summary_BASH-R_${thislogdate}"

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
#  Create PBS files
#................................................

## Write PBS header
cut -f1 ${input} | sort | uniq | while read stem; do echo "#!/bin/sh" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "##########################################################################" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#  Script:  ${pbs_stem}_${stem}_${thislogdate}.pbs" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#  Author:  Isabela Almeida" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#  Created: ${human_thislogdate} at QIMR Berghofer (Brisbane, Australia) - VSC" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#  Updated: ${human_thislogdate} at QIMR Berghofer (Brisbane, Australia) - VSC" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#  Version: v01" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#  Email:   ${email}" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "##########################################################################" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

## Write PBS directives
cut -f1 ${input} | sort | uniq | while read stem; do echo "#PBS -N ${pbs_stem}_${stem}_${thislogdate}" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#PBS -r n" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#PBS -l mem=${mem}GB,walltime=${walltime},ncpus=${ncpus}" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#PBS -m abe" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#PBS -M ${email}" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

## Write directory setting
cut -f1 ${input} | sort | uniq | while read stem; do echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#  Set main working directory" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "## Change to main directory" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo 'cd ${PBS_O_WORKDIR}' >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo 'echo ; echo "WARNING: The main directory for this run was set to ${PBS_O_WORKDIR}"; echo ' >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

## Write PBS command lines
cut -f1 ${input} | sort | uniq | while read stem; do echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#  Run step" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo 'echo "## Write counts to TSV at" ; date ; echo' >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do libraryfasta=`grep "${stem}" ${input} | cut -f8 | sort | uniq`; r1=`grep "${stem}" ${input} | cut -f2`; r2=`grep "${stem}" ${input} | cut -f3`; r3=`grep "${stem}" ${input} | cut -f4`; normr1=`grep "${stem}" ${input} | cut -f5`; normr2=`grep "${stem}" ${input} | cut -f6`; normr3=`grep "${stem}" ${input} | cut -f7`; echo "echo -e \"target\trep1-counts\tctrl-1-counts\trep2-counts\tctrl-2-counts\trep3-counts\tctrl-3-counts\tnorm-rep1-counts\tnorm-ctrl-1-counts\tnorm-rep2-counts\tnorm-ctrl-2-counts\tnorm-rep3-counts\tnorm-ctrl-3-counts\" > ${out_path_step033_summary}/${stem}_per-target.tsv; grep \"^>\" ${libraryfasta} | cut -c 2- | while read target; do r1c=\`grep -w \"\${target}\" ${r1} | cut -f3\`; ctrl1c=\`grep -w \"\${target}\" ${r1} | cut -f4\`; r2c=\`grep -w \"\${target}\" ${r2} | cut -f3\`; ctrl2c=\`grep -w \"\${target}\" ${r2} | cut -f4\`; r3c=\`grep -w \"\${target}\" ${r3} | cut -f3\`; ctrl3c=\`grep -w \"\${target}\" ${r3} | cut -f4\`; nr1c=\`grep -w \"\${target}\" ${normr1} | cut -f3\`; nctrl1c=\`grep -w \"\${target}\" ${normr1} | cut -f4\`; nr2c=\`grep -w \"\${target}\" ${normr2} | cut -f3\`; nctrl2c=\`grep -w \"\${target}\" ${normr2} | cut -f4\`; nr3c=\`grep -w \"\${target}\" ${normr3} | cut -f3\`; nctrl3c=\`grep -w \"\${target}\" ${normr3} | cut -f4\`; if [ -z \"\${r1c}\" ]; then r1c=NA ; fi ; if [ -z \"\${ctrl1c}\" ]; then ctrl1c=NA ; fi ; if [ -z \"\${r2c}\" ]; then r2c=NA ; fi ; if [ -z \"\${ctrl2c}\" ]; then ctrl2c=NA ; fi ; if [ -z \"\${r3c}\" ]; then r3c=NA ; fi ; if [ -z \"\${ctrl3c}\" ]; then ctrl3c=NA ; fi ; echo -e \"\${target}\t\${r1c}\t\${ctrl1c}\t\${r2c}\t\${ctrl2c}\t\${r3c}\t\${ctrl3c}\t\${nr1c}\t\${nctrl1c}\t\${nr2c}\t\${nctrl2c}\t\${nr3c}\t\${nctrl3c}\" >> ${out_path_step033_summary}/${stem}_per-target.tsv ; done" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

cut -f1 ${input} | sort | uniq | while read stem; do echo 'echo "## Plot results at" ; date ; echo' >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do rscript=`grep "${stem}" ${input} | cut -f9 | sort | uniq`; rfunctions=`grep "${stem}" ${input} | cut -f10 | sort | uniq`; echo "Rscript ${rscript} --input ${out_path_step033_summary}/${stem}_per-target.tsv --outdir ${out_path_step033_summary} --outstem ${stem} --function ${rfunctions}" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

#................................................
#  Submit PBS jobs
#................................................

## Submit PBS jobs 
ls ${pbs_stem}_*${thislogdate}.pbs | while read pbs; do echo ; echo "#................................................" ; echo "# This is PBS: ${pbs}" ;  echo "#" ; echo "# main command line(s): $(tail -n4 ${pbs} | head -n1)" ; echo "#                       $(tail -n1 ${pbs})" ; echo "#" ; echo "# now submitting PBS" ; echo "qsub ${pbs}" ; qsub ${pbs} ; echo "#................................................" ; done

date ## Status of all user jobs (including CAMeLS step 033 jobs) at
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
sed -i 's,${out_path_step033_summary},'"${out_path_step033_summary}"',g' "$logfile"
sed -i 's,${logfile},'"${logfile}"',g' "$logfile"
sed -n -e :a -e '1,3!{P;N;D;};N;ba' $logfile > tmp ; mv tmp $logfile
set +v