#!/bin/bash
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
                            /path/from/working/dir/to/camels041_stats-combined_MAGeCK_DATE/stem*.gene_summary.txt

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

                            Col8:
                            /path/from/working/dir/to/library.tsv
                            file with guideid\tguide-sequence\tgene-name

                            Col9:
                            /path/from/working/dir/to/targets-info.tsv
                            containing
                            chr \t start \t end \t id \t score \t strand \t type \t name \t ucsc-location \t notes

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
cut -f1 ${input} | sort | uniq | while read file; do target=`grep "${file}" ${input} | cut -f5 | sort | uniq`; celltype=`grep "${file}" ${input} | cut -f2 | sort | uniq`; positive=`grep "${file}" ${input} | cut -f4 | sort | uniq`; negative=`grep "${file}" ${input} | cut -f3 | sort | uniq`; gtf=`grep "${file}" ${input} | cut -f6 | sort | uniq`; stem=`echo ${file} | rev | cut -d'/' -f1 | cut -d'.' -f3- | rev | cut -d'_' -f2`;

cat ${file} | awk 'NR==1 {print}; NR>1{if($11<0.1) {print}}' > ${out_path_step042_summary}/${celltype}_${stem}_FDR0p1.pos.gene_summary.txt
cat ${file} | awk 'NR==1 {print}; NR>1{if($11<0.2) {print}}' > ${out_path_step042_summary}/${celltype}_${stem}_FDR0p2.pos.gene_summary.txt
cat ${file} | awk 'NR==1 {print}; NR>1{if($11<0.3) {print}}' > ${out_path_step042_summary}/${celltype}_${stem}_FDR0p3.pos.gene_summary.txt
cat ${file} | awk 'NR==1 {print}; NR>1{if($11<0.4) {print}}' > ${out_path_step042_summary}/${celltype}_${stem}_FDR0p4.pos.gene_summary.txt
cat ${file} | awk 'NR==1 {print}; NR>1{if($11<0.5) {print}}' > ${out_path_step042_summary}/${celltype}_${stem}_FDR0p5.pos.gene_summary.txt
cat ${file} | awk 'NR==1 {print}; NR>1{if(($11>=0.5)&&($11<=1)) {print}}' > ${out_path_step042_summary}/${celltype}_${stem}_FDRb0p5.pos.gene_summary.txt
cat ${file} | awk 'NR==1 {print}; NR>1{if($11==1) {print}}' > ${out_path_step042_summary}/${celltype}_${stem}_FDR1.pos.gene_summary.txt
cat ${file} | awk 'NR==1 {print}; NR>1{if($11==0) {print}}' > ${out_path_step042_summary}/${celltype}_${stem}_FDR0.pos.gene_summary.txt

cat ${file} | awk 'NR==1 {print}; NR>1{if($5<0.1) {print}}' > ${out_path_step042_summary}/${celltype}_${stem}_FDR0p1.neg.gene_summary.txt
cat ${file} | awk 'NR==1 {print}; NR>1{if($5<0.2) {print}}' > ${out_path_step042_summary}/${celltype}_${stem}_FDR0p2.neg.gene_summary.txt
cat ${file} | awk 'NR==1 {print}; NR>1{if($5<0.3) {print}}' > ${out_path_step042_summary}/${celltype}_${stem}_FDR0p3.neg.gene_summary.txt
cat ${file} | awk 'NR==1 {print}; NR>1{if($5<0.4) {print}}' > ${out_path_step042_summary}/${celltype}_${stem}_FDR0p4.neg.gene_summary.txt
cat ${file} | awk 'NR==1 {print}; NR>1{if($5<0.5) {print}}' > ${out_path_step042_summary}/${celltype}_${stem}_FDR0p5.neg.gene_summary.txt
cat ${file} | awk 'NR==1 {print}; NR>1{if(($5>=0.5)&&($5<=1)) {print}}' > ${out_path_step042_summary}/${celltype}_${stem}_FDRb0p5.neg.gene_summary.txt
cat ${file} | awk 'NR==1 {print}; NR>1{if($5==1) {print}}' > ${out_path_step042_summary}/${celltype}_${stem}_FDR1.neg.gene_summary.txt
cat ${file} | awk 'NR==1 {print}; NR>1{if($5==0) {print}}' > ${out_path_step042_summary}/${celltype}_${stem}_FDR0.neg.gene_summary.txt

done

date ## Identify pos/neg/target counts passing MAGeCK test FDR# at
while read file; do
    target=$(grep "${file}" ${input} | cut -f5 | sort | uniq);
    celltype=$(grep "${file}" ${input} | cut -f2 | sort | uniq);
    positive=$(grep "${file}" ${input} | cut -f4 | sort | uniq);
    negative=$(grep "${file}" ${input} | cut -f3 | sort | uniq);
    gtf=$(grep "${file}" ${input} | cut -f6 | sort | uniq);
    stem=$(echo ${file} | rev | cut -d'/' -f1 | cut -d'.' -f3- | rev | cut -d'_' -f2);

    while read stats; do
        mainstats=$(echo "${stats}" | rev | cut -d'/' -f1 | cut -d'.' -f2- | rev)
        
        # positives
        while read pos; do
            grep -w "${pos}" ${stats} >> ${out_path_step042_summary}/${mainstats}.posctrl.txt

        done < ${positive}

        # negatives
        while read neg; do
            grep -w "${neg}" ${stats} >> ${out_path_step042_summary}/${mainstats}.negctrl.txt
        done < ${negative}

        # targets
        while read tar; do
            grep -w "${tar}" ${stats} >> ${out_path_step042_summary}/${mainstats}.targets.txt
        done < ${target}

    done < <(ls ${out_path_step042_summary}/${celltype}_${stem}*.gene_summary.txt)
done < <(cut -f1 ${input} | sort | uniq)

date ## Write summary counts passing MAGeCK test FDR# to TSV at
cut -f1 ${input} | sort | uniq | while read file; do target=`grep "${file}" ${input} | cut -f5 | sort | uniq`; celltype=`grep "${file}" ${input} | cut -f2 | sort | uniq`; positive=`grep "${file}" ${input} | cut -f4 | sort | uniq`; negative=`grep "${file}" ${input} | cut -f3 | sort | uniq`; gtf=`grep "${file}" ${input} | cut -f6 | sort | uniq`; library=`grep "${file}" ${input} | cut -f7 | sort | uniq`; stem=`echo ${file} | rev | cut -d'/' -f1 | cut -d'.' -f3- | rev | cut -d'_' -f2`;

# all counts - total (positive and negative hits)
grossFDR0p1=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p1.*gene_summary.txt`;
grossFDR0p2=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p2.*gene_summary.txt`;
grossFDR0p3=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p3.*gene_summary.txt`;
grossFDR0p4=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p4.*gene_summary.txt`;
grossFDR0p5=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p5.*gene_summary.txt`;
grossFDRb0p5=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDRb0p5.*gene_summary.txt`;
grossFDR1=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR1.*gene_summary.txt`;
grossFDR0=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0.*gene_summary.txt`;

# all counts - positive hits
grossFDR0p1pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p1.pos.gene_summary.txt`;
grossFDR0p2pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p2.pos.gene_summary.txt`;
grossFDR0p3pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p3.pos.gene_summary.txt`;
grossFDR0p4pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p4.pos.gene_summary.txt`;
grossFDR0p5pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p5.pos.gene_summary.txt`;
grossFDRb0p5pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDRb0p5.pos.gene_summary.txt`;
grossFDR1pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR1.pos.gene_summary.txt`;
grossFDR0pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0.pos.gene_summary.txt`;

# all counts - negative hits
grossFDR0p1neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p1.neg.gene_summary.txt`;
grossFDR0p2neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p2.neg.gene_summary.txt`;
grossFDR0p3neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p3.neg.gene_summary.txt`;
grossFDR0p4neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p4.neg.gene_summary.txt`;
grossFDR0p5neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p5.neg.gene_summary.txt`;
grossFDRb0p5neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDRb0p5.neg.gene_summary.txt`;
grossFDR1neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR1.neg.gene_summary.txt`;
grossFDR0neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0.neg.gene_summary.txt`;

# positive controls counts - total (positive and negative hits)
posFDR0p1=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p1.*gene_summary.posctrl.txt`;
posFDR0p2=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p2.*gene_summary.posctrl.txt`;
posFDR0p3=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p3.*gene_summary.posctrl.txt`;
posFDR0p4=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p4.*gene_summary.posctrl.txt`;
posFDR0p5=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p5.*gene_summary.posctrl.txt`;
posFDRb0p5=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDRb0p5.*gene_summary.posctrl.txt`;
posFDR1=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR1.*gene_summary.posctrl.txt`;
posFDR0=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0.*gene_summary.posctrl.txt`;

# positive controls counts - positive hits
posFDR0p1pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p1.pos.gene_summary.posctrl.txt`;
posFDR0p2pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p2.pos.gene_summary.posctrl.txt`;
posFDR0p3pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p3.pos.gene_summary.posctrl.txt`;
posFDR0p4pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p4.pos.gene_summary.posctrl.txt`;
posFDR0p5pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p5.pos.gene_summary.posctrl.txt`;
posFDRb0p5pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDRb0p5.pos.gene_summary.posctrl.txt`;
posFDR1pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR1.pos.gene_summary.posctrl.txt`;
posFDR0pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0.pos.gene_summary.posctrl.txt`;

# positive controls counts - negative hits
posFDR0p1neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p1.neg.gene_summary.posctrl.txt`;
posFDR0p2neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p2.neg.gene_summary.posctrl.txt`;
posFDR0p3neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p3.neg.gene_summary.posctrl.txt`;
posFDR0p4neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p4.neg.gene_summary.posctrl.txt`;
posFDR0p5neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p5.neg.gene_summary.posctrl.txt`;
posFDRb0p5neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDRb0p5.neg.gene_summary.posctrl.txt`;
posFDR1neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR1.neg.gene_summary.posctrl.txt`;
posFDR0neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0.neg.gene_summary.posctrl.txt`;

# negative controls counts - total (positive and negative hits)
negFDR0p1=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p1.*gene_summary.negctrl.txt`;
negFDR0p2=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p2.*gene_summary.negctrl.txt`;
negFDR0p3=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p3.*gene_summary.negctrl.txt`;
negFDR0p4=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p4.*gene_summary.negctrl.txt`;
negFDR0p5=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p5.*gene_summary.negctrl.txt`;
negFDRb0p5=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDRb0p5.*gene_summary.negctrl.txt`;
negFDR1=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR1.*gene_summary.negctrl.txt`;
negFDR0=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0.*gene_summary.negctrl.txt`;

# negative controls counts - positive hits
negFDR0p1pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p1.pos.gene_summary.negctrl.txt`;
negFDR0p2pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p2.pos.gene_summary.negctrl.txt`;
negFDR0p3pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p3.pos.gene_summary.negctrl.txt`;
negFDR0p4pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p4.pos.gene_summary.negctrl.txt`;
negFDR0p5pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p5.pos.gene_summary.negctrl.txt`;
negFDRb0p5pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDRb0p5.pos.gene_summary.negctrl.txt`;
negFDR1pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR1.pos.gene_summary.negctrl.txt`;
negFDR0pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0.pos.gene_summary.negctrl.txt`;

# negative counts - negative hits
negFDR0p1neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p1.neg.gene_summary.negctrl.txt`;
negFDR0p2neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p2.neg.gene_summary.negctrl.txt`;
negFDR0p3neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p3.neg.gene_summary.negctrl.txt`;
negFDR0p4neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p4.neg.gene_summary.negctrl.txt`;
negFDR0p5neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p5.neg.gene_summary.negctrl.txt`;
negFDRb0p5neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDRb0p5.neg.gene_summary.negctrl.txt`;
negFDR1neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR1.neg.gene_summary.negctrl.txt`;
negFDR0neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0.neg.gene_summary.negctrl.txt`;

# target counts - total (positive and negative hits)
tarFDR0p1=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p1.*gene_summary.targets.txt`;
tarFDR0p2=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p2.*gene_summary.targets.txt`;
tarFDR0p3=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p3.*gene_summary.targets.txt`;
tarFDR0p4=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p4.*gene_summary.targets.txt`;
tarFDR0p5=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p5.*gene_summary.targets.txt`;
tarFDRb0p5=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDRb0p5.*gene_summary.targets.txt`;
tarFDR1=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR1.*gene_summary.targets.txt`;
tarFDR0=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0.*gene_summary.targets.txt`;

# target counts - positive hits
tarFDR0p1pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p1.pos.gene_summary.targets.txt`;
tarFDR0p2pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p2.pos.gene_summary.targets.txt`;
tarFDR0p3pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p3.pos.gene_summary.targets.txt`;
tarFDR0p4pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p4.pos.gene_summary.targets.txt`;
tarFDR0p5pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p5.pos.gene_summary.targets.txt`;
tarFDRb0p5pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDRb0p5.pos.gene_summary.targets.txt`;
tarFDR1pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR1.pos.gene_summary.targets.txt`;
tarFDR0pos=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0.pos.gene_summary.targets.txt`;

# target counts - negative hits
tarFDR0p1neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p1.neg.gene_summary.targets.txt`;
tarFDR0p2neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p2.neg.gene_summary.targets.txt`;
tarFDR0p3neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p3.neg.gene_summary.targets.txt`;
tarFDR0p4neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p4.neg.gene_summary.targets.txt`;
tarFDR0p5neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0p5.neg.gene_summary.targets.txt`;
tarFDRb0p5neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDRb0p5.neg.gene_summary.targets.txt`;
tarFDR1neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR1.neg.gene_summary.targets.txt`;
tarFDR0neg=`awk 'END{print NR}' ${out_path_step042_summary}/${celltype}_${stem}_FDR0.neg.gene_summary.targets.txt`;

# write to TSV file
echo -e "${celltype}\t${stem}\tall-genes\t${grossFDR0p1}\t${grossFDR0p1pos}\t${grossFDR0p1neg}\t${grossFDR0p2}\t${grossFDR0p2pos}\t${grossFDR0p2neg}\t${grossFDR0p3}\t${grossFDR0p3pos}\t${grossFDR0p3neg}\t${grossFDR0p4}\t${grossFDR0p4pos}\t${grossFDR0p4neg}\t${grossFDR0p5}\t${grossFDR0p5pos}\t${grossFDR0p5neg}\t${grossFDRb0p5}\t${grossFDRb0p5pos}\t${grossFDRb0p5neg}\t${grossFDR1}\t${grossFDR1pos}\t${grossFDR1neg}\t${grossFDR0}\t${grossFDR0pos}\t${grossFDR0neg}" >> ${out_path_step042_summary}/summary_FDR-stats-${library}.tsv
echo -e "${celltype}\t${stem}\tpos-ctrls\t${posFDR0p1}\t${posFDR0p1pos}\t${posFDR0p1neg}\t${posFDR0p2}\t${posFDR0p2pos}\t${posFDR0p2neg}\t${posFDR0p3}\t${posFDR0p3pos}\t${posFDR0p3neg}\t${posFDR0p4}\t${posFDR0p4pos}\t${posFDR0p4neg}\t${posFDR0p5}\t${posFDR0p5pos}\t${posFDR0p5neg}\t${posFDRb0p5}\t${posFDRb0p5pos}\t${posFDRb0p5neg}\t${posFDR1}\t${posFDR1pos}\t${posFDR1neg}\t${posFDR0}\t${posFDR0pos}\t${posFDR0neg}" >> ${out_path_step042_summary}/summary_FDR-stats-${library}.tsv
echo -e "${celltype}\t${stem}\tneg-ctrls\t${negFDR0p1}\t${negFDR0p1pos}\t${negFDR0p1neg}\t${negFDR0p2}\t${negFDR0p2pos}\t${negFDR0p2neg}\t${negFDR0p3}\t${negFDR0p3pos}\t${negFDR0p3neg}\t${negFDR0p4}\t${negFDR0p4pos}\t${negFDR0p4neg}\t${negFDR0p5}\t${negFDR0p5pos}\t${negFDR0p5neg}\t${negFDRb0p5}\t${negFDRb0p5pos}\t${negFDRb0p5neg}\t${negFDR1}\t${negFDR1pos}\t${negFDR1neg}\t${negFDR0}\t${negFDR0pos}\t${negFDR0neg}" >> ${out_path_step042_summary}/summary_FDR-stats-${library}.tsv
echo -e "${celltype}\t${stem}\ttargets\t${tarFDR0p1}\t${tarFDR0p1pos}\t${tarFDR0p1neg}\t${tarFDR0p2}\t${tarFDR0p2pos}\t${tarFDR0p2neg}\t${tarFDR0p3}\t${tarFDR0p3pos}\t${tarFDR0p3neg}\t${tarFDR0p4}\t${tarFDR0p4pos}\t${tarFDR0p4neg}\t${tarFDR0p5}\t${tarFDR0p5pos}\t${tarFDR0p5neg}\t${tarFDRb0p5}\t${tarFDRb0p5pos}\t${tarFDRb0p5neg}\t${tarFDR1}\t${tarFDR1pos}\t${tarFDR1neg}\t${tarFDR0}\t${tarFDR0pos}\t${tarFDR0neg}" >> ${out_path_step042_summary}/summary_FDR-stats-${library}.tsv ; done

# add header to TSV file
ls ${out_path_step042_summary}/summary_FDR-stats*.tsv | while read file; do sed -i '1 i\cell-type\tnormalisation\tgene-counts\tall-hits-FDR0.1\tpos-hits-FDR0.1\tneg-hits-FDR0.1\tall-hits-FDR0.2\tpos-hits-FDR0.2\tneg-hits-FDR0.2\tall-hits-FDR0.3\tpos-hits-FDR0.3\tneg-hits-FDR0.3\tall-hits-FDR0.4\tpos-hits-FDR0.4\tneg-hits-FDR0.4\tall-hits-FDR0.5\tpos-hits-FDR0.5\tneg-hits-FDR0.5\tall-hits-1<FDR<0.5\tpos-hits-1<FDR<0.5\tneg-hits-1<FDR<0.5\tall-hits-FDR1\tpos-hits-FDR1\tneg-hits-FDR1\tall-hits-FDR0\tpos-hits-FDR0\tneg-hits-FDR0' ${file} ; done

date ## Create TSV info file and GTF for ucsc session at
while read tar; do
    gtf=$(grep "${lib}" ${input} | cut -f6 | sort | uniq);
    library=$(grep "${lib}" ${input} | cut -f8 | sort | uniq);
    folder=$(grep "${lib}" ${input} | cut -f1 | rev | cut -d'/' -f2- | sort | uniq);
    ucsc=$(grep "${lib}" ${input} | cut -f9 | sort | uniq);

    grep -w "${tar}" ${folder}/*.sgrna_summary.txt | cut -d':' -f2- | cut -f1 | sort | uniq | while read sgrna; do guides=`grep "${sgrna}" ${library} | cut -f2 | sort | uniq | tr '\n' ',' | sed 's/,$//'`; posh=`if grep -wq "${tar}" ${out_path_step042_summary}/*.pos.targets.txt; then echo yes; else echo none; fi`; pfdr=`grep -w "${tar}" ${out_path_step042_summary}/*.pos.targets.txt | cut -f11 | tr '\n' ',' | sed 's/,$//'`; negh=`if grep -wq "${tar}" ${out_path_step042_summary}/${celltype}_${stem}.neg.targets.txt; then echo yes; else echo none; fi`; nfdr=`grep -w "${tar}" ${out_path_step042_summary}/${celltype}_${stem}.neg.targets.txt | cut -f5 | tr '\n' ',' | sed 's/,$//'`; norm=`grep -w "${tar}" ${folder}/*.sgrna_summary.txt | cut -d':' -f1 | rev | cut -d'/' -f1 | cut -d'.' -f5- | cut -d'_' -f1 | cut -d'-' -f3 | rev | sort | uniq | tr '\n' ',' | sed 's/,$//'`; samples=`grep -w "${tar}" ${folder}/*.sgrna_summary.txt | cut -d':' -f1 | rev | cut -d'/' -f1 | cut -d'.' -f5- | cut -d'_' -f2- | rev | sort | uniq | tr '\n' ',' | sed 's/,$//'`; cutoffs=`grep -w "${tar}" ${folder}/*.sgrna_summary.txt | cut -d':' -f1 | rev | cut -d'/' -f1 | cut -d'.' -f4 | cut -d'_' -f1 | rev | sort | uniq | tr '\n' ',' | sed 's/,$//'`; ucscinfo=`grep -w "${tar}" ${ucsc}`; echo -e "\t${t}\t${guides}\t${posh}\t${pfdr}\t${negh}\t${nfdr}\t${norm}\t${samples}\t${cutoffs}\t${ucscinfo}" ; done >> ${out_path_step042_summary}/${library}.targets.tsv

    grep "${tar}" ${gtf} | cut -d':' -f2- >> ${out_path_step042_summary}/${library}.targets.gtf

done < <(cut -f1 ${out_path_step042_summary}/*targets.txt | sort | uniq)


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