#!/bin/bash

version="1.0.0"
usage(){
echo "
Written by Isabela Almeida
Created on May 06, 2026
Last modified on May 07, 2026
Version: ${version}

Description: Write and submit PBS jobs for Step 043 of the
CAMeLS pipeline (CRISPR Analysis Method for Library Screens). 

Usage: bash ipda_camels_step043-to-pbs.sh -i "path/to/input/files" -p "PBS stem" -e "email" -m INT -c INT -w "HH:MM:SS"

Resources used for pipeline in-house: -m 1 -c 1 -w "01:00:00"

## Input:

-i <path/to/input/files>    Input TSV files including path FROM working
                            directory. This TSV file should contain:
                            
                            Col1:
                            stem-sample

                            Col2:
                            /path/from/working/dir/to/camels041_stats-combined_MAGeCK_DATE/stem-all-replicates
                            stem of .gene_summary.txt .sgrna_summary.txt files

                            Col3:
                            /path/from/working/dir/to/library_info.tsv
                            Note: must contain col7 with type (e.g. pc coding, lncRNA); col8 with id/name (e.g. TP53) and col18 with UCSC location (e.g. chr17:7668421-7687490)

                            Col4:
                            /path/from/working/dir/to/transcriptome.gtf
                            Note: transcript lines must have gene_name on col10 and transcript_name on col16 (double-quote delimited fields)

                            Col5:
                            /path/from/working/dir/to/pos-ctrl-genes.tsv
                            Note: col1 must contain id and col2 gene/transcript name

                            Col6:
                            /path/from/working/dir/to/CAMeLS/scripts/ipda_camels_step043.r

                            Col7:
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
#   020 Guide representation (1BBDuk - finds 23nt perfect matchs and 21nt 0,2 and 3MM, 2BASH - write to TSV, 3R plot results)
#   030 Count reads from FASTQ files (1MAGeCK - replicate level; 2MAGeCK - combined replicates; 3Bash - summary replicates; 4Bash - summary combined)
#-->040 Statistical test (1MAGeCK; 2Bash summary; 3R plot results)
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
        ?) echo script usage: bash ipda_camels_step043-to-pbs.sh -i path/to/input/files -p PBS stem -e email -m INT -c INT -w "HH:MM:SS" >&2
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
logfile=logfile_ipda_camels043-to-pbs_${thislogdate}.txt

#................................................
#  Set and create output path
#................................................

## Set stem for output directories
out_path_step043_summary="camels043_plots_BASH-R_${thislogdate}"

## Create output directories
mkdir -p ${out_path_step043_summary}

#................................................
#  Required modules, softwares and libraries
#................................................

# R 4.5.0
module_R="R/4.5.0"

#................................................
#  Print Execution info to user
#................................................

date
echo "## Executing bash ipda_camels_step043-to-pbs.sh"
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
echo "## Output files saved to:       ${out_path_step043_summary}"
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
echo "## Executing bash ipda_camels_step043-to-pbs.sh"
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
echo "## Output files saved to:       ${out_path_step043_summary}"
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

## Write load modules
cut -f1 ${input} | sort | uniq | while read stem; do echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#  Load Softwares, Libraries and Modules" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "module load ${module_R}" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done


## Write PBS command lines
cut -f1 ${input} | sort | uniq | while read stem; do echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#  Run step" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo 'echo "## Create gene_summary full TSV at" ; date ; echo' >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do in_stem=`grep "${stem}" ${input} | cut -f2 | sort | uniq`; library_info=`grep "${stem}" ${input} | cut -f3 | sort | uniq`; transcriptome=`grep "${stem}" ${input} | cut -f4 | sort | uniq`; pos=`grep "${stem}" ${input} | cut -f5 | sort | uniq`; echo "cat ${in_stem}.gene_summary.txt | while read l; do id=\`echo \$l | cut -d' ' -f1 | cut -d'_' -f1 | cut -d'.' -f1\`; if [[ \"\$id\" == *NODE* || \"\$id\" =~ ^[0-9] || \"\$id\" == *ENSGRNA* ]]; then id_full=\`echo \$l | cut -d' ' -f1\`; flag=\"yes\"; else id_full=\`echo \$l | cut -d' ' -f1 | cut -d'_' -f1\`; flag=\"no\"; fi; info=\`awk -v id=\"\$id_full\" '\$4 == id' ${library_info} | cut -f7,8,18\`; type=\`echo \"\$info\" | cut -f1\`; name=\"\${id_full}\"; if [ -n \"\$info\" ] ; then if echo \"\$info\" | grep -q \"HyDRA_lncRNA\"; then name=\`echo \"\$info\" | cut -f3\`; else name=\`echo \"\$info\" | cut -f2\`; fi; fi; if [[ \"\$name\" == \"\$id_full\" && \"\$flag\" == \"no\" ]]; then if [[ \"\$name\" == *ENST* ]]; then name=\`grep -P \"\ttranscript\t.*\${id_full}\" ${transcriptome} | cut -d'\"' -f16 | sort | uniq\`; elif [[ \"\$name\" == *ENSG* ]]; then name=\`grep -P \"\ttranscript\t.*\${id}\" ${transcriptome} | cut -d'\"' -f10 | sort | uniq\`; fi; fi; if [ -z \"\$type\" ]; then if grep -q \"\${id}\" ${pos}; then type=\"pos-ctrl\"; elif [ \"\$id\" == *ENSGRNA* ]; then type=\"lncRNA\"; else type=\"neg-ctrl\"; fi; fi; if [ \${id} == \"id\" ] ; then echo -e \"\${l}\tgene_name\ttype\"; else echo -e \"\${l}\t\${name}\t\${type}\"; fi; done > ${out_path_step043_summary}/${stem}.gene_summary.full.tsv" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

cut -f1 ${input} | sort | uniq | while read stem; do echo 'echo "## Create sgrna_summary full TSV at" ; date ; echo' >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do in_stem=`grep "${stem}" ${input} | cut -f2 | sort | uniq`; library_info=`grep "${stem}" ${input} | cut -f3 | sort | uniq`; transcriptome=`grep "${stem}" ${input} | cut -f4 | sort | uniq`; pos=`grep "${stem}" ${input} | cut -f5 | sort | uniq`; echo "cat ${in_stem}.sgrna_summary.txt | while read l; do id=\`echo \$l | cut -d' ' -f2 | cut -d'_' -f1 | cut -d'.' -f1\`; if [[ \"\$id\" == *NODE* || \"\$id\" =~ ^[0-9] || \"\$id\" == *ENSGRNA* ]]; then id_full=\`echo \$l | cut -d' ' -f2\`; flag=\"yes\"; else id_full=\`echo \$l | cut -d' ' -f2 | cut -d'_' -f1\`; flag=\"no\"; fi; info=\`awk -v id=\"\$id_full\" '\$4 == id' ${library_info} | cut -f7,8,18\`; type=\`echo \"\$info\" | cut -f1\`; name=\"\${id_full}\"; if [ -n \"\$info\" ] ; then if echo \"\$info\" | grep -q \"HyDRA_lncRNA\"; then name=\`echo \"\$info\" | cut -f3\`; else name=\`echo \"\$info\" | cut -f2\`; fi; fi; if [[ \"\$name\" == \"\$id_full\" && \"\$flag\" == \"no\" ]]; then if [[ \"\$name\" == *ENST* ]]; then name=\`grep -P \"\ttranscript\t.*\${id_full}\" ${transcriptome} | cut -d'\"' -f16 | sort | uniq\`; elif [[ \"\$name\" == *ENSG* ]]; then name=\`grep -P \"\ttranscript\t.*\${id}\" ${transcriptome} | cut -d'\"' -f10 | sort | uniq\`; fi; fi; if [ -z \"\$type\" ]; then if grep -q \"\${id}\" ${pos}; then type=\"pos-ctrl\"; elif [ \"\$id\" == *ENSGRNA* ]; then type=\"lncRNA\"; else type=\"neg-ctrl\"; fi; fi; if [ \${id} == \"sgrna\" ] ; then echo -e \"\${l}\tgene_name\ttype\"; else echo -e \"\${l}\t\${name}\t\${type}\"; fi; done > ${out_path_step043_summary}/${stem}.sgrna_summary.full.tsv" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

cut -f1 ${input} | sort | uniq | while read stem; do echo 'echo "## Plot results at" ; date ; echo' >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do rscript=`grep "${stem}" ${input} | cut -f6 | sort | uniq`; rfunctions=`grep "${stem}" ${input} | cut -f7 | sort | uniq`; echo "Rscript ${rscript} --inputgene ${out_path_step043_summary}/${stem}.gene_summary.full.tsv --inputsgrna ${out_path_step043_summary}/${stem}.sgrna_summary.full.tsv --outdir ${out_path_step043_summary} --outstem ${stem} --function ${rfunctions}" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

#................................................
#  Submit PBS jobs
#................................................

## Submit PBS jobs 
ls ${pbs_stem}_*${thislogdate}.pbs | while read pbs; do echo ; echo "#................................................" ; echo "# This is PBS: ${pbs}" ;  echo "#" ; echo "# main command line(s): $(tail -n7 ${pbs} | head -n1)" ; echo "#                       $(tail -n4 ${pbs} | head -n1)" ; echo "#                       $(tail -n1 ${pbs})" ; echo "#" ; echo "# now submitting PBS" ; echo "qsub ${pbs}" ; qsub ${pbs} ; echo "#................................................" ; done

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
sed -i 's,${module_R},'"${module_R}"',g' "$logfile"
sed -i 's,${out_path_step043_summary},'"${out_path_step043_summary}"',g' "$logfile"
sed -i 's,${logfile},'"${logfile}"',g' "$logfile"
sed -n -e :a -e '1,3!{P;N;D;};N;ba' $logfile > tmp ; mv tmp $logfile
set +v