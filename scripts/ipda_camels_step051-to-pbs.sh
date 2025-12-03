#!/bin/bash

version="1.0.0"
usage(){
echo "
Written by Isabela Almeida
Based on CASE by Maina Bitar
Created on December 02, 2025
Last modified on December 03, 2025
Version: ${version}

Description: Write and submit PBS jobs for Step 051 of the
CAMeLS pipeline (CRISPR Analysis Method for Library Screens). 

Usage: bash ipda_camels_step051-to-pbs.sh -i "path/to/input/files" -p "PBS stem" -e "email" -m INT -c INT -w "HH:MM:SS"

Resources used for pipeline in-house: -m 10 -c 1 -w "05:00:00"

## Input:

-i <path/to/input/files>    Input TSV files including path FROM working
                            directory. This TSV file should contain:
                            
                            Col1:
                            cell type
                            E.g. FT194

                            Col2:
                            /path/from/working/dir/to/negative-controls-id.txt

                            Col3:
                            path to MAGeCK count files, e.g.:
                            /path/from/working/dir/to/camels032_counts-combined_MAGeCK_DATE/

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
#   040 Statistical test (1MAGeCK; 2Bash summary)
#-->050 Plot results (1MAGeCK)

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
        ?) echo script usage: bash ipda_camels_step051-to-pbs.sh -i path/to/input/files -p PBS stem -e email -m INT -c INT -w "HH:MM:SS" >&2
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
logfile=logfile_ipda_camels051-to-pbs_${thislogdate}.txt

#................................................
#  Required modules, softwares and libraries
#................................................

# MAGeCK:
# <https://sourceforge.net/projects/mageck/>
module_mageck="conda-envs/mageck-0.5.9.5"

# Rstudio
module_rstudio="rstudio/R-3.6.2"

#................................................
#  Set and create output path
#................................................

## Set stem for output directories
out_path_step051_MAGeCK="camels051_plots_MAGeCK_${thislogdate}"

## Create output directories
mkdir -p ${out_path_step051_MAGeCK}

#................................................
#  Print Execution info to user
#................................................

date
echo "## Executing bash ipda_camels_step051-to-pbs.sh"
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
echo "## Output files saved to:       ${out_path_step051_MAGeCK}"
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
echo "## Executing bash ipda_camels_step051-to-pbs.sh"
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
echo "## Output files saved to:       ${out_path_step051_MAGeCK}"
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
cut -f1 ${input} | sort | uniq | while read stem; do echo "module load ${module_mageck}" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "module load ${module_rstudio}" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

## Write Rmd file
cut -f1 ${input} | sort | uniq | while read stem; do echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#  Write Rmd file" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "---" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "title: \"MAGeCK Flute\"" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "subtitle: \"${stem}\"" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "author: \"Isabela Almeida\"" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "date: \"\`r Sys.Date()\`\"" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "output: rmdformats::downcute" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "---" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`{r setup, include=FALSE}" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo 'knitr::opts_chunk$set(echo=TRUE, message=TRUE)' >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done

cut -f1 ${input} | sort | uniq | while read stem; do echo "# Load Libraries" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`{r load-libraries, echo=TRUE, message=FALSE}" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "library(\"MAGeCKFlute\")" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "library(\"ggplot2\")" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done

cut -f1 ${input} | sort | uniq | while read stem; do echo "# Load Data" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "Gene summary file (MAGeCK output gene-level):" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`{r gdata-paths}" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do file=`grep "${stem}" ${input} | cut -f2 | sort | uniq`; echo "gdata = read.delim(file=\"${file}.gene_summary.txt\", check.names = FALSE)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "head(gdata)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "Guide summary file (MAGeCK output guide-level):" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`{r sdata-paths}" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do file=`grep "${stem}" ${input} | cut -f2 | sort | uniq`; echo "sdata = read.delim(file=\"${file}.sgrna_summary.txt\")" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "head(sdata)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "Count summary file (MAGeCK output guide-level):" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`{r cdata-paths}" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do file=`grep "${stem}" ${input} | cut -f2 | sort | uniq`; echo "cdata = read.delim(file=\"${file}.countsummary.txt\", check.names = FALSE)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "head(cdata)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done

cut -f1 ${input} | sort | uniq | while read stem; do echo "# Run MAGeCK Flute" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done

cut -f1 ${input} | sort | uniq | while read stem; do echo "Gini index:" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`{r gini-index}" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "tiff(\"${out_path_step051_MAGeCK}/${stem}_GiniIndex.tiff\", units=\"in\", width=15, height=15, res=300)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "BarView(cdata, x = \"Label\", y = \"GiniIndex\", ylab = \"Gini index\", main = \"Evenness of sgRNA reads\")" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "dev.off()" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done

cut -f1 ${input} | sort | uniq | while read stem; do echo "Missed sgRNAs:" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`{r missed-sgrnas}" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "cdata\$Missed = log10(cdata\$Zerocounts)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "tiff(\"${out_path_step051_MAGeCK}/${stem}_MissedGuides.tiff\", units=\"in\", width=15, height=15, res=300)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "BarView(cdata, x = \"Label\", y = \"Missed\", fill = \"#394E80\", ylab = \"Log10 missed gRNAs\", main = \"Missed sgRNAs\")" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "dev.off()" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done

cut -f1 ${input} | sort | uniq | while read stem; do echo "Read mapping:" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`{r read-mapping}" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "tiff(\"${out_path_step051_MAGeCK}/${stem}_ReadMapping.tiff\", units=\"in\", width=15, height=15, res=300)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "MapRatesView(cdata)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "dev.off()" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done

cut -f1 ${input} | sort | uniq | while read stem; do echo "Guide ranking:" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`{r guide-ranking}" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "p2 = sgRankView(sdata, top = 10, bottom = 10)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "tiff(\"${out_path_step051_MAGeCK}/${stem}_GuideFC.tiff\", units="in", width=20, height=20, res=300)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "print(p2)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "dev.off()" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done

cut -f1 ${input} | sort | uniq | while read stem; do echo "Volcano plots:" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`{r volcano-plot}" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "gdata\$LogFDR = -log10(gdata\$FDR)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "p1 = ScatterView(gdata, x = \"Score\", y = \"LogFDR\", label = \"id\", model = \"volcano\", top = 10)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "tiff(\"${out_path_step051_MAGeCK}/${stem}_VolcanoPlot_v1.tiff\", units=\"in\", width=15, height=15, res=300)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "print(p1)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "dev.off()" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "gdata\$LogFDR = -log10(gdata\$FDR)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "p2 = VolcanoView(gdata, x = \"Score\", y = \"FDR\", Label = \"id\")" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "tiff(\"${out_path_step051_MAGeCK}/${stem}_VolcanoPlot_v2.tiff\", units=\"in\", width=15, height=15, res=300)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "print(p2)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "dev.off()" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done

cut -f1 ${input} | sort | uniq | while read stem; do echo "Plot genes in relation to ranking:" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`{r plot-ranking}" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "gdata\$Rank = rank(gdata\$Score) " >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "p1 = ScatterView(gdata, x = \"Rank\", y = \"Score\", label = \"id\", top = 15, auto_cut_y = TRUE, ylab = \"Log2FC\", groups = c(\"top\", \"bottom\"), max.overlaps=100)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "tiff(\"${out_path_step051_MAGeCK}/${stem}_RankPlot.tiff\", units=\"in\", width=15, height=15, res=300)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "print(p1)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "dev.off()" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done

cut -f1 ${input} | sort | uniq | while read stem; do echo "Plot genes in relation to logFC:" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`{r plot-logFC}" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "tiff(\"${out_path_step051_MAGeCK}/${stem}_FoldChangePlot_v1.tiff\", units=\"in\", width=15, height=15, res=300)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "ScatterView(gdata, x = \"Score\", y = \"Rank\", label = \"id\", auto_cut_x = TRUE, groups = c(\"left\", \"right\"), xlab = \"Log2FC\", top = 5, max.overlaps=100)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "dev.off()" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "geneList= gdata\$Score" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "names(geneList) = gdata\$id" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "p2 = RankView(geneList, top = 20, bottom = 20, max.overlaps=100) + xlab(\"Log2FC\")" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "tiff(\"${out_path_step051_MAGeCK}/${stem}_FoldChangePlot_v2.tiff\", units=\"in\", width=5, height=5, res=300)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "print(p2)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "dev.off()" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done

cut -f1 ${input} | sort | uniq | while read stem; do echo "Highlight genes of interest (GOIs)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`{r highlight-genes}" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "gois = c(\"ENSG00000265334.1\", \"ENSG00000272609.1\", \"ENSG00000253681.1\", \"NODE_518103_length_493_cov_38.995305_g333637_i0\")" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "tiff(\"${out_path_step051_MAGeCK}/${stem}_FoldChangePlot_GOIs.tiff\", units=\"in\", width=5, height=5, res=300)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "RankView(geneList, top = 0, bottom = 0, genelist = gois) + xlab(\"Log2FC\")" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "dev.off()" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done

cut -f1 ${input} | sort | uniq | while read stem; do echo "Plot the positive hits only:" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`{r plot-pos-hits}" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "gdata\$Rank = rank(-gdata\$Score)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "tiff(\"${out_path_step051_MAGeCK}/${stem}_PositiveHits.tiff\", units=\"in\", width=5, height=5, res=300)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "ScatterView(gdata[gdata\$Score>0,], x = \"Rank\", y = \"Score\", label = \"id\", auto_cut_y = TRUE, groups = c(\"top\", \"bottom\"), ylab = \"Log2FC\", top = 15, max.overlaps=100)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "dev.off()" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done

cut -f1 ${input} | sort | uniq | while read stem; do echo "Plot the negative hits only:" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`{r guide-ranking}" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "gdata\$Rank = rank(-gdata\$Score)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "tiff(\"${out_path_step051_MAGeCK}/${stem}_NegativeHits.tiff\", units=\"in\", width=5, height=5, res=300)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "ScatterView(gdata[gdata\$Score<0,], x = \"Rank\", y = \"Score\", label = \"id\", auto_cut_y = TRUE, groups = c(\"top\", \"bottom\"), ylab = \"Log2FC\", top = 15, max.overlaps=100)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "dev.off()" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done

cut -f1 ${input} | sort | uniq | while read stem; do echo "Dot plots:" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`{r dot-plot}" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "gdata\$RandomIndex = sample(1:nrow(gdata), nrow(gdata))" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "gdata = gdata[order(-gdata\$Score), ]" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "gg = gdata[gdata\$Score>0, ]" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "p1 = ScatterView(gg, x = \"RandomIndex\", y = \"Score\", label = \"id\", y_cut = CutoffCalling(gdata\$Score,2), groups = \"top\", top = 15, ylab = \"Log2FC\")" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "tiff(\"${out_path_step051_MAGeCK}/${stem}_DotPlotPositives.tiff\", units=\"in\", width=10, height=10, res=300)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "p1" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "dev.off()" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "gg = gdata[gdata\$Score<0, ]" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "p2 = ScatterView(gg, x = \"RandomIndex\", y = \"Score\", label = \"id\", y_cut = CutoffCalling(gdata\$Score,2), groups = \"bottom\", top = 15, ylab = \"Log2FC\")" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "tiff(\"${out_path_step051_MAGeCK}/${stem}_DotPlotNegatives.tiff\", units=\"in\", width=10, height=10, res=300)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "p2" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "dev.off()" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done

cut -f1 ${input} | sort | uniq | while read stem; do echo "Plot gene enrichment:" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`{r plot-genrichment}" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "geneList= gdata\$Score" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "names(geneList) = gdata\$id" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "enrich = EnrichAnalyzer(geneList = geneList[geneList>0.25], method = \"HGT\", type = \"KEGG\")" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "tiff(\"${out_path_step051_MAGeCK}/${stem}_KEGGenrichment_v1.tiff\", units=\"in\", width=10, height=10, res=300)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "EnrichedView(enrich, mode = 1, top = 20)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "dev.off()" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "tiff(\"${out_path_step051_MAGeCK}/${stem}_KEGGenrichment_v2.tiff\", units=\"in\", width=10, height=10, res=300)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "EnrichedView(enrich, mode = 2, top = 20)" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "dev.off()" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "\`\`\`" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${out_path_step051_MAGeCK}/${stem}.Rmd; done

## Write PBS command lines
cut -f1 ${input} | sort | uniq | while read stem; do echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#  Run step" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "#................................................" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo 'echo "## Run MAGeCK Flute at" ; date ; echo' >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do echo "Rscript -e \"rmarkdown::render('${out_path_step051_MAGeCK}/${stem}.Rmd', output_format = 'html_notebook')\"" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

#................................................
#  Submit PBS jobs
#................................................

## Submit PBS jobs 
ls ${pbs_stem}_*${thislogdate}.pbs | while read pbs; do echo ; echo "#................................................" ; echo "# This is PBS: ${pbs}" ;  echo "#" ; echo "# main command line(s): $(tail -n1 ${pbs})" ; echo "#                       $(tail -n1 ${pbs})" ; echo "#" ; echo "# now submitting PBS" ; echo "qsub ${pbs}" ; qsub ${pbs} ; echo "#................................................" ; done

date ## Status of all user jobs (including CAMeLS step 051 jobs) at
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
sed -i 's,${module_rstudio},'"${module_rstudio}"',g' "$logfile"
sed -i 's,${out_path_step051_MAGeCK},'"${out_path_step051_MAGeCK}"',g' "$logfile"
sed -i 's,${logfile},'"${logfile}"',g' "$logfile"
sed -n -e :a -e '1,3!{P;N;D;};N;ba' $logfile > tmp ; mv tmp $logfile
set +v