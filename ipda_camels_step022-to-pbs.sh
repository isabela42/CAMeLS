#!/bin/bash

version="1.0.0"
usage(){
echo "
Written by Isabela Almeida
Based on CASE by Maina Bitar
Created on May 21, 2025
Last modified on September 15, 2025
Version: ${version}

Description: Write and submit PBS jobs for Step 022 of the
CAMeLS pipeline (CRISPR Analysis Method for Library Screens). 

Usage: bash ipda_camels_step022-to-pbs.sh -i "path/to/input/files" -p "PBS stem" -e "email" -m INT -c INT -w "HH:MM:SS"

Resources used for pipeline in-house: -m 1 -c 1 -w "01:00:00"

## Input:

-i <path/to/input/files>    Input TSV files including path FROM working
                            directory. This TSV file should contain:
                            
                            Col1:
                            stem-library-name

                            Col2:
                            /path/from/working/dir/to/camels021_plasmid-rep_BBDuk_DATE/perfect-*-match_stats_replicate1

                            Col3:
                            /path/from/working/dir/to/camels021_plasmid-rep_BBDuk_DATE/perfect-*-match_stats_replicate2

                            Col4:
                            /path/from/working/dir/to/camels021_plasmid-rep_BBDuk_DATE/perfect-*-match_stats_replicate3

                            Col5:
                            /path/from/working/dir/to/library.fasta

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
#-->020 Plasmid-representation (1BBDuk - finds 23nt perfect matchs and 21nt 0,2 and 3MM, 2BASH - write to TSV)

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
        ?) echo script usage: bash ipda_camels_step022-to-pbs.sh -i path/to/input/files -p PBS stem -e email -m INT -c INT -w "HH:MM:SS" >&2
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
logfile=logfile_ipda_camels022-to-pbs_${thislogdate}.txt

#................................................
#  Set and create output path
#................................................

## Set stem for output directories
out_path_step022_BASH="camels022_plasmid-rep_BASH_${thislogdate}"

## Create output directories
mkdir -p ${out_path_step022_BASH}

#................................................
#  Print Execution info to user
#................................................

date
echo "## Executing bash ipda_camels_step022-to-pbs.sh"
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
echo "## Output files saved to:       ${out_path_step022_BASH}"
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
echo "## Executing bash ipda_camels_step022-to-pbs.sh"
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
echo "## Output files saved to:       ${out_path_step022_BASH}"
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
cut -f1 ${input} | sort | uniq | while read stem; do libraryfasta=`grep "${stem}" ${input} | cut -f5 | sort | uniq`; r1=`grep "${stem}" ${input} | cut -f2`; r2=`grep "${stem}" ${input} | cut -f3`; r3=`grep "${stem}" ${input} | cut -f4`; echo "echo -e \"target\trep1-counts\trep-1-perc\trep2-counts\trep-2-perc\trep3-counts\trep-3-perc\" > ${out_path_step022_BASH}/plasmid-representation_${stem}_per-target.tsv; grep \"^>\" ${libraryfasta} | cut -c 2- | while read target; do r1c=\`grep -w \"\${target}\" ${r1} | cut -f2\`; r1p=\`grep -w \"\${target}\" ${r1} | cut -f3\`; r2c=\`grep -w \"\${target}\" ${r2} | cut -f2\`; r2p=\`grep -w \"\${target}\" ${r2} | cut -f3\`; r3c=\`grep -w \"\${target}\" ${r3} | cut -f2\`; r3p=\`grep -w \"\${target}\" ${r3} | cut -f3\`; if [ -z \"\${r1c}\" ]; then r1c=NA ; fi ; if [ -z \"\${r1p}\" ]; then r1c=NA ; fi ; if [ -z \"\${r2c}\" ]; then r1c=NA ; fi ; if [ -z \"\${r2p}\" ]; then r1c=NA ; fi ; if [ -z \"\${r3c}\" ]; then r1c=NA ; fi ; if [ -z \"\${r3p}\" ]; then r1c=NA ; fi ; echo -e \"\${target}\t\${r1c}\t\${r1p}\t\${r2c}\t\${r2p}\t\${r3c}\t\${r3p}\" >> ${out_path_step022_BASH}/plasmid-representation_${stem}_per-target.tsv ; done" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

cut -f1 ${input} | sort | uniq | while read stem; do echo 'echo "## Write overal counts report at" ; date ; echo' >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do libraryfasta=`grep "${stem}" ${input} | cut -f5 | sort | uniq`; librarysize=`grep -c "^>" ${libraryfasta}`; r1=`grep "${stem}" ${input} | cut -f2`; r2=`grep "${stem}" ${input} | cut -f3`; r3=`grep "${stem}" ${input} | cut -f4`; echo "echo -e \"Replicate#\tcounts>=200\tperc>=200\tcount-undetected\tperc-undetected\" > ${out_path_step022_BASH}/plasmid-representation_${stem}_full-library.tsv; rep1c=\`tail -n+5 ${r1} | awk '\$2>=200{c++} END{print c+0}'\` ; rep2c=\`tail -n+5 ${r2} | awk '\$2>=200{c++} END{print c+0}'\` ; rep3c=\`tail -n+5 ${r3} | awk '\$2>=200{c++} END{print c+0}'\` ; rep1p=\`awk -v r1c=\"\$rep1c\" -v t=\"$librarysize\" 'BEGIN { print (r1c / t) * 100 }'\` ; rep2p=\`awk -v r2c=\"\$rep2c\" -v t=\"$librarysize\" 'BEGIN { print (r2c / t) * 100 }'\` ; rep3p=\`awk -v r3c=\"\$rep3c\" -v t=\"$librarysize\" 'BEGIN { print (r3c / t) * 100 }'\` ; rep1t=\`tail -n+5 ${r1} | awk 'END{print NR}'\`; rep2t=\`tail -n+5 ${r2} | awk 'END{print NR}'\`; rep3t=\`tail -n+5 ${r3} | awk 'END{print NR}'\`; rep1u=\`awk -v r1t=\"\$rep1t\" -v t=\"$librarysize\" 'BEGIN { print t - r1t }'\` ; rep2u=\`awk -v r2t=\"\$rep2t\" -v t=\"$librarysize\" 'BEGIN { print t - r2t }'\` ; rep3u=\`awk -v r3t=\"\$rep3t\" -v t=\"$librarysize\" 'BEGIN { print t - r3t }'\` ; rep1up=\`awk -v r1u=\"\$rep1u\" -v t=\"$librarysize\" 'BEGIN { print (r1u / t) * 100 }'\` ; rep2up=\`awk -v r2u=\"\$rep2u\" -v t=\"$librarysize\" 'BEGIN { print (r2u / t) * 100 }'\` ; rep3up=\`awk -v r3u=\"\$rep3u\" -v t=\"$librarysize\" 'BEGIN { print (r3u / t) * 100 }'\` ; echo -e \"Replicate1\t\${rep1c}\t\${rep1p}\t\${rep1u}\t\${rep1up}\nReplicate2\t\${rep2c}\t\${rep2p}\t\${rep2u}\t\${rep2up}\nReplicate3\t\${rep3c}\t\${rep3p}\t\${rep3u}\t\${rep3up}\" >> ${out_path_step022_BASH}/plasmid-representation_${stem}_full-library.tsv" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

#................................................
#  Submit PBS jobs
#................................................

## Submit PBS jobs 
ls ${pbs_stem}_*${thislogdate}.pbs | while read pbs; do echo ; echo "#................................................" ; echo "# This is PBS: ${pbs}" ;  echo "#" ; echo "# main command line(s): $(tail -n4 ${pbs} | head -n1)" ; echo "#                       $(tail -n1 ${pbs})" ; echo "#" ; echo "# now submitting PBS" ; echo "qsub ${pbs}" ; qsub ${pbs} ; echo "#................................................" ; done

date ## Status of all user jobs (including CAMeLS step 022 jobs) at
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
sed -i 's,${out_path_step022_BASH},'"${out_path_step022_BASH}"',g' "$logfile"
sed -i 's,${logfile},'"${logfile}"',g' "$logfile"
sed -n -e :a -e '1,3!{P;N;D;};N;ba' $logfile > tmp ; mv tmp $logfile
set +v