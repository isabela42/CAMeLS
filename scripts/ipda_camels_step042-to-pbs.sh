#!/bin/bash
source ~/.bashrc

version="1.0.0"
usage(){
echo "
Written by Isabela Almeida
Created on September 26, 2025
Last modified on September 30, 2025
Version: ${version}

Description: Write and submit PBS jobs for Step 042 of the
CAMeLS pipeline (CRISPR Analysis Method for Library Screens). 

Usage: bash ipda_camels_step042-to-pbs.sh -i "path/to/input/files" -p "PBS stem" -e "email" -m INT -c INT -w "HH:MM:SS"

Resources used for pipeline in-house: -m 1 -c 1 -w "01:00:00"

## Input:

-i <path/to/input/files>    Input TSV files including path FROM working
                            directory. This TSV file should contain:
                            
                            Col1:
                            /path/from/working/dir/to/camels03*_counts-*_MAGeCK_DATE_backup/stem-all-replicates.gene_summary.txt

                            Col2:
                            cell type
                            E.g. FT194

                            Col3:
                            /path/from/working/dir/to/negative-controls-id.txt

                            Col4:
                            /path/from/working/dir/to/positive-controls-id.txt

                            Col5:
                            /path/from/working/dir/to/targets-id.txt

                            Col6:
                            /path/from/working/dir/to/targets.gtf

                            Col7:
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
#   030 Count reads from FASTQ files (1MAGeCK - replicate level; 2MAGeCK - combined replicates; 3Bash - summary replicates; 4Bash - summary combined)
#-->040 Statistical test (1MAGeCK; 2Bash summary)
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
        ?) echo script usage: bash ipda_camels_step042-to-pbs.sh -i path/to/input/files -p PBS stem -e email -m INT -c INT -w "HH:MM:SS" >&2
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
logfile=logfile_ipda_camels042-to-pbs_${thislogdate}.txt

#................................................
#  Set and create output path
#................................................

## Set stem for output directories
out_path_step042_summary="camels042_FDR-counts_summary_${thislogdate}"

## Create output directories
mkdir -p ${out_path_step042_summary}

#................................................
#  Print Execution info to user
#................................................

date
echo "## Executing bash ipda_camels_step042-to-pbs.sh"
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
echo "## Output files saved to:       ${out_path_step042_summary}"
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
echo "## Executing bash ipda_camels_step042-to-pbs.sh"
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
echo "## Output files saved to:       ${out_path_step042_summary}"
echo "## This is logfile:             ${logfile}"

set -v

#................................................
#  Summary of count reads
#................................................

date ## Filter genes passing MAGeCK test FDR# at
cut -f1 ${input} | sort | uniq | while read file; do target=`grep "${file}" ${input} | cut -f5 | sort | uniq`; celltype=`grep "${file}" ${input} | cut -f2 | sort | uniq`; positive=`grep "${file}" ${input} | cut -f4 | sort | uniq`; negative=`grep "${file}" ${input} | cut -f3 | sort | uniq`; gtf=`grep "${file}" ${input} | cut -f6 | sort | uniq`; stem=`echo ${file} | rev | cut -d'/' -f1 | rev | cut -d'_' -f2`;

cat ${file} | awk 'NR==1 {print}; NR>1{if(($5<0.1)||($11<0.1)) {print}}' > ${out_path_step042_summary}/${celltype}_${stem}_FDR0p1.gene_summary.txt
cat ${file} | awk 'NR==1 {print}; NR>1{if(($5<0.2)||($11<0.2)) {print}}' > ${out_path_step042_summary}/${celltype}_${stem}_FDR0p2.gene_summary.txt
cat ${file} | awk 'NR==1 {print}; NR>1{if(($5<0.3)||($11<0.3)) {print}}' > ${out_path_step042_summary}/${celltype}_${stem}_FDR0p3.gene_summary.txt
cat ${file} | awk 'NR==1 {print}; NR>1{if(($5<0.4)||($11<0.4)) {print}}' > ${out_path_step042_summary}/${celltype}_${stem}_FDR0p4.gene_summary.txt
cat ${file} | awk 'NR==1 {print}; NR>1{if(($5<0.5)||($11<0.5)) {print}}' > ${out_path_step042_summary}/${celltype}_${stem}_FDR0p5.gene_summary.txt
cat ${file} | awk 'NR==1 {print}; NR>1{if((($5>=0.5)&&($5<=1))||(($11>=0.5)&&($11<=1))) {print}}' > ${out_path_step042_summary}/${celltype}_${stem}_FDRb0p5.gene_summary.txt
cat ${file} | awk 'NR==1 {print}; NR>1{if(($5==1)||($11==1)) {print}}' > ${out_path_step042_summary}/${celltype}_${stem}_FDR1.gene_summary.txt
cat ${file} | awk 'NR==1 {print}; NR>1{if(($5==0)||($11==0)) {print}}' > ${out_path_step042_summary}/${celltype}_${stem}_FDR0.gene_summary.txt

done

date ## Identify pos/neg/target counts passing MAGeCK test FDR# at

# positives
cut -f1 ${input} | sort | uniq | while read file; do target=`grep "${file}" ${input} | cut -f5 | sort | uniq`; celltype=`grep "${file}" ${input} | cut -f2 | sort | uniq`; positive=`grep "${file}" ${input} | cut -f4 | sort | uniq`; negative=`grep "${file}" ${input} | cut -f3 | sort | uniq`; gtf=`grep "${file}" ${input} | cut -f6 | sort | uniq`; stem=`echo ${file} | rev | cut -d'/' -f1 | rev | cut -d'_' -f2`; ls ${out_path_step042_summary}/${celltype}_${stem}*.gene_summary.txt | while read stats; do cat ${positive} | while read pos; do mainstats=`echo ${stats} | rev | cut -d'/' -f1 | cut -d'.' -f2- | rev`; grep -w "${pos}" ${stats} >> ${out_path_step042_summary}/${mainstats}.positives.txt ; done ; done; done

# negatives
cut -f1 ${input} | sort | uniq | while read file; do target=`grep "${file}" ${input} | cut -f5 | sort | uniq`; celltype=`grep "${file}" ${input} | cut -f2 | sort | uniq`; positive=`grep "${file}" ${input} | cut -f4 | sort | uniq`; negative=`grep "${file}" ${input} | cut -f3 | sort | uniq`; gtf=`grep "${file}" ${input} | cut -f6 | sort | uniq`; stem=`echo ${file} | rev | cut -d'/' -f1 | rev | cut -d'_' -f2`; ls ${out_path_step042_summary}/${celltype}_${stem}*.gene_summary.txt  | while read stats; do cat ${negative} | while read neg; do mainstats=`echo ${stats} | rev | cut -d'/' -f1 | cut -d'.' -f2- | rev`; grep -w "${neg}" ${stats} >> ${out_path_step042_summary}/${mainstats}.negatives.txt ; done ; done; done

# targets
cut -f1 ${input} | sort | uniq | while read file; do target=`grep "${file}" ${input} | cut -f5 | sort | uniq`; celltype=`grep "${file}" ${input} | cut -f2 | sort | uniq`; positive=`grep "${file}" ${input} | cut -f4 | sort | uniq`; negative=`grep "${file}" ${input} | cut -f3 | sort | uniq`; gtf=`grep "${file}" ${input} | cut -f6 | sort | uniq`; stem=`echo ${file} | rev | cut -d'/' -f1 | rev | cut -d'_' -f2`; ls ${out_path_step042_summary}/${celltype}_${stem}*.gene_summary.txt  | while read stats; do cat ${target} | while read tar; do mainstats=`echo ${stats} | rev | cut -d'/' -f1 | cut -d'.' -f2- | rev`; grep -w "${tar}" ${stats} >> ${out_path_step042_summary}/${mainstats}.targets.txt ; grep -w "${tar}" ${gtf} >> ${out_path_step042_summary}/${mainstats}.targets.gtf; done ; done ; done

date ## Write summary counts passing MAGeCK test FDR# to TSV at
cut -f1 ${input} | sort | uniq | while read file; do target=`grep "${file}" ${input} | cut -f5 | sort | uniq`; celltype=`grep "${file}" ${input} | cut -f2 | sort | uniq`; positive=`grep "${file}" ${input} | cut -f4 | sort | uniq`; negative=`grep "${file}" ${input} | cut -f3 | sort | uniq`; gtf=`grep "${file}" ${input} | cut -f6 | sort | uniq`; library=`grep "${file}" ${input} | cut -f7 | sort | uniq`; stem=`echo ${file} | rev | cut -d'/' -f1 | rev | cut -d'_' -f2`;

# all counts
grossFDR0p1=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDR0p1.gene_summary.txt | wc -l`;
grossFDR0p2=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDR0p2.gene_summary.txt | wc -l`;
grossFDR0p3=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDR0p3.gene_summary.txt | wc -l`;
grossFDR0p4=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDR0p4.gene_summary.txt | wc -l`;
grossFDR0p5=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDR0p5.gene_summary.txt | wc -l`;
grossFDRb0p5=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDRb0p5.gene_summary.txt | wc -l`;
grossFDR1=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDR1.gene_summary.txt | wc -l`;
grossFDR0=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDR0.gene_summary.txt | wc -l`;

# positive counts
posFDR0p1=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDR0p1.gene_summary.positives.txt | wc -l`;
posFDR0p2=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDR0p2.gene_summary.positives.txt | wc -l`;
posFDR0p3=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDR0p3.gene_summary.positives.txt | wc -l`;
posFDR0p4=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDR0p4.gene_summary.positives.txt | wc -l`;
posFDR0p5=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDR0p5.gene_summary.positives.txt | wc -l`;
posFDRb0p5=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDRb0p5.gene_summary.positives.txt | wc -l`;
posFDR1=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDR1.gene_summary.positives.txt | wc -l`;
posFDR0=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDR0.gene_summary.positives.txt | wc -l`;

# negative counts
negFDR0p1=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDR0p1.gene_summary.negatives.txt | wc -l`;
negFDR0p2=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDR0p2.gene_summary.negatives.txt | wc -l`;
negFDR0p3=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDR0p3.gene_summary.negatives.txt | wc -l`;
negFDR0p4=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDR0p4.gene_summary.negatives.txt | wc -l`;
negFDR0p5=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDR0p5.gene_summary.negatives.txt | wc -l`;
negFDRb0p5=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDRb0p5.gene_summary.negatives.txt | wc -l`;
negFDR1=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDR1.gene_summary.negatives.txt | wc -l`;
negFDR0=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDR0.gene_summary.negatives.txt | wc -l`;

# target counts
tarFDR0p1=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDR0p1.gene_summary.targets.txt | wc -l`;
tarFDR0p2=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDR0p2.gene_summary.targets.txt | wc -l`;
tarFDR0p3=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDR0p3.gene_summary.targets.txt | wc -l`;
tarFDR0p4=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDR0p4.gene_summary.targets.txt | wc -l`;
tarFDR0p5=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDR0p5.gene_summary.targets.txt | wc -l`;
tarFDRb0p5=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDRb0p5.gene_summary.targets.txt | wc -l`;
tarFDR1=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDR1.gene_summary.targets.txt | wc -l`;
tarFDR0=`tail -n+2 ${out_path_step042_summary}/${celltype}_${stem}_FDR0.gene_summary.targets.txt | wc -l`;

# write to TSV file
echo -e "${celltype}\t${stem}\tall-genes\t${grossFDR0p1}\t${grossFDR0p2}\t${grossFDR0p3}\t${grossFDR0p4}\t${grossFDR0p5}\t${grossFDRb0p5}\t${grossFDR1}\t${grossFDR0}" >> ${out_path_step042_summary}/summary_FDR-stats-${library}.tsv
echo -e "${celltype}\t${stem}\tpos-ctrls\t${posFDR0p1}\t${posFDR0p2}\t${posFDR0p3}\t${posFDR0p4}\t${posFDR0p5}\t${posFDRb0p5}\t${posFDR1}\t${posFDR0}" >> ${out_path_step042_summary}/summary_FDR-stats-${library}.tsv
echo -e "${celltype}\t${stem}\tneg-ctrls\t${negFDR0p1}\t${negFDR0p2}\t${negFDR0p3}\t${negFDR0p4}\t${negFDR0p5}\t${negFDRb0p5}\t${negFDR1}\t${negFDR0}" >> ${out_path_step042_summary}/summary_FDR-stats-${library}.tsv
echo -e "${celltype}\t${stem}\ttargets\t${tarFDR0p1}\t${tarFDR0p2}\t${tarFDR0p3}\t${tarFDR0p4}\t${tarFDR0p5}\t${tarFDRb0p5}\t${tarFDR1}\t${tarFDR0}" >> ${out_path_step042_summary}/summary_FDR-stats-${library}.tsv ; done

# add header to TSV file
ls ${out_path_step042_summary}/summary_FDR-stats*.tsv | while read file; do sed -i '1 i\cell-type\tnormalisation\tgene-counts\tFDR0.1\tFDR0.2\tFDR0.3\tFDR0.4\tFDR0.5\t1<FDR<0.5\tFDR1\tFDR0' ${file} ; done

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
sed -i 's,${out_path_step042_summary},'"${out_path_step042_summary}"',g' "$logfile"
sed -i 's,${logfile},'"${logfile}"',g' "$logfile"
sed -n -e :a -e '1,3!{P;N;D;};N;ba' $logfile > tmp ; mv tmp $logfile
set +v