#!/bin/bash

version="1.0.0"
usage(){
echo "
Written by Isabela Almeida
Created on May 06, 2026
Last modified on Nov 20, 2026
Version: ${version}

Description: Write and submit PBS jobs for Step 043 of the
CAMeLS pipeline (CRISPR Analysis Method for Library Screens). 

Usage: bash ipda_camels_step043-to-pbs.sh -i "path/to/input/files" -p "PBS stem" -e "email" -m INT -c INT -w "HH:MM:SS"

Resources used for pipeline in-house: -m 1 -c 1 -w "01:00:00"

## Input:

-i <path/to/input/files>    Input TSV files including path FROM working
                            directory. This TSV file should contain (no header):
                            
                            Col1:
                            stem-sample

                            Col2:
                            /path/from/working/dir/to/camels041_stats-combined_MAGeCK_DATE/stem-all-replicates
                            stem of .gene_summary.txt .sgrna_summary.txt files

                            Col3:
                            /path/from/working/dir/to/negative-controls-id.txt

                            Col4:
                            /path/from/working/dir/to/positive-controls-id.txt

                            Col5:
                            /path/from/working/dir/to/targets-id.txt

                            Col6 (optional, may be left empty):
                            /path/from/working/dir/to/transcriptome.gtf
                            Plain-text GTF used to name genes (gene_name) and set their type
                            (gene_type/gene_biotype). IDs are matched to gene_id, gene_name or
                            transcript_id; Ensembl IDs are matched ignoring version and suffixes.

                            Col7:
                            /path/from/working/dir/to/CAMeLS/scripts/ipda_camels_step043.r

                            Col8:
                            /path/from/working/dir/to/CAMeLS/scripts/ipda_camels_rfunctions.r

                            Col9:
                            /path/from/working/dir/to/camels034_combined-summary_BASH-R_DATE/stem_per-target.tsv

                            Col10:
                            /path/from/working/dir/to/camels033_replicate-summary_BASH-R_DATE/stem_per-target.tsv

                            Col11:
                            <fdr|pval>
                            Statistic used to call significant hits

                            Col12:
                            FLOAT
                            Threshold for calling significant hits (kept if statistic < threshold)

                            Type assigned to each gene/sgRNA: pos-ctrl or neg-ctrl if in Col4/Col3;
                            otherwise the GTF type; otherwise lncRNA for ENSGRNA IDs; otherwise
                            target if in Col5; otherwise other.

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
#  Validate input file and columns
#................................................

if [ -z "${input}" ] || [ ! -f "${input}" ]; then
    echo "ERROR: input TSV (-i) not given or not found: ${input}" >&2; exit 1
fi

awk -F'\t' '
function missing(f,   line, r) { r = (getline line < f); close(f); return (r < 0) }
{
    s = tolower($11); t = $12
    if ($1 !~ /^[A-Za-z0-9._-]+$/) { print "ERROR line " NR ": col1 must contain only letters, digits, . _ - (got \"" $1 "\")" > "/dev/stderr"; bad = 1 }
    if (s != "fdr" && s != "pval") { print "ERROR line " NR ": col11 must be fdr or pval (got \"" $11 "\")" > "/dev/stderr"; bad = 1 }
    if (!(t+0 == t && t > 0 && t <= 1)) { print "ERROR line " NR ": col12 must be a number in (0,1] (got \"" t "\")" > "/dev/stderr"; bad = 1 }
    for (i = 1; i <= 12; i++) if (i != 6 && $i == "") { print "ERROR line " NR ": col" i " is empty" > "/dev/stderr"; bad = 1 }
    if ($2 != "" && missing($2 ".gene_summary.txt"))  { print "ERROR line " NR ": not found: " $2 ".gene_summary.txt" > "/dev/stderr"; bad = 1 }
    if ($2 != "" && missing($2 ".sgrna_summary.txt")) { print "ERROR line " NR ": not found: " $2 ".sgrna_summary.txt" > "/dev/stderr"; bad = 1 }
    split("3 4 5 6 7 8 9 10", fc, " ")
    for (j in fc) { i = fc[j]; if ($i != "" && missing($i)) { print "ERROR line " NR ": col" i " file not found: " $i > "/dev/stderr"; bad = 1 } }
}
END { exit bad }' ${input} || exit 1

#................................................
#  Helpers
#................................................

## Usage: col STEM N
## Prints column N of the input row(s) whose Col1 is exactly STEM
col(){ awk -F'\t' -v s="$1" -v c="$2" '$1 == s {print $c}' ${input} | sort -u; }

## Usage: gtf_lookup "path/to/targets.gtf"   (same as step 042)
## Prints one line per gene_id / gene_name / transcript_id:
## id chr start end strand type name ucsc-location
gtf_lookup(){ awk -F'\t' -v OFS='\t' '
    $0 ~ /^#/ || NF < 9 { next }
    {
        delete A; n = split($9, kv, ";")
        for (i = 1; i <= n; i++) {
            p = kv[i]; gsub(/^ +| +$/, "", p); if (p == "") continue
            k = p; sub(/ .*/, "", k); v = p; sub(/^[^ ]+ +/, "", v); gsub(/"/, "", v); A[k] = v
        }
        typ = ("gene_type" in A) ? A["gene_type"] : (("gene_biotype" in A) ? A["gene_biotype"] : $3)
        nm  = ("gene_name" in A) ? A["gene_name"] : A["gene_id"]
        split("gene_id gene_name transcript_id", keys, " ")
        for (j = 1; j <= 3; j++) {
            if (!(keys[j] in A)) continue
            id = A[keys[j]]
            if (!(id in CHR)) { CHR[id] = $1; S[id] = $4+0; E[id] = $5+0; STR[id] = $7; TYP[id] = typ; NM[id] = nm; order[++m] = id }
            else { if ($4+0 < S[id]) S[id] = $4+0; if ($5+0 > E[id]) E[id] = $5+0 }
        }
    }
    END { for (x = 1; x <= m; x++) { id = order[x]; print id, CHR[id], S[id], E[id], STR[id], TYP[id], NM[id], CHR[id] ":" S[id] "-" E[id] } }' "$1"; }

## Usage: annotate_summary SUMMARY IDCOL NEG POS TARGETS LOOKUP
## Appends gene_name and type to a MAGeCK gene_summary (IDCOL 1) or sgrna_summary (IDCOL 2)
annotate_summary(){ awk -F'\t' -v OFS='\t' -v idc="$2" '
    ## Ensembl IDs are matched to the GTF on their stable ID only (ENST00000427076.5_P1 -> ENST00000427076)
    function unver(x) { if (x ~ /^ENSGRNA/) return x; if (match(x, /^ENS[A-Z]*[0-9]+/)) return substr(x, 1, RLENGTH); return x }
    FILENAME==ARGV[1] {N[$1]; next}
    FILENAME==ARGV[2] {P[$1]; next}
    FILENAME==ARGV[3] {T[$1]; next}
    FILENAME==ARGV[4] {TY[unver($1)] = $6; NM[unver($1)] = $7; next}
    FNR==1 {print $0, "gene_name", "type"; next}
    {
        id = $idc; k = unver(id)
        name = (k in NM) ? NM[k] : id
        if      (id in P)          type = "pos-ctrl"
        else if (id in N)          type = "neg-ctrl"
        else if (k in TY)          type = TY[k]
        else if (id ~ /^ENSGRNA/)  type = "lncRNA"
        else if (id in T)          type = "target"
        else                       type = "other"
        print $0, name, type
    }' "$3" "$4" "$5" "$6" "$1"; }

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
#  Annotate gene and sgRNA summaries
#................................................

date ## Build one id-to-annotation lookup per GTF (col6) at
while read gtf; do
    gtf_lookup ${gtf} > ${out_path_step043_summary}/gtf-lookup_$(echo "${gtf}" | cksum | cut -d' ' -f1).tsv
done < <(awk -F'\t' '$6 != "" && !seen[$6]++ {print $6}' ${input})

date ## Create gene_summary and sgrna_summary full TSVs at
cut -f1 ${input} | sort | uniq | while read stem; do
    in_stem=$(col ${stem} 2); negative=$(col ${stem} 3); positive=$(col ${stem} 4); target=$(col ${stem} 5); gtf=$(col ${stem} 6)
    if [ -n "${gtf}" ]; then lookup=${out_path_step043_summary}/gtf-lookup_$(echo "${gtf}" | cksum | cut -d' ' -f1).tsv; else lookup=/dev/null; fi
    annotate_summary ${in_stem}.gene_summary.txt  1 ${negative} ${positive} ${target} ${lookup} > ${out_path_step043_summary}/${stem}.gene_summary.full.tsv
    annotate_summary ${in_stem}.sgrna_summary.txt 2 ${negative} ${positive} ${target} ${lookup} > ${out_path_step043_summary}/${stem}.sgrna_summary.full.tsv
done

date ## Remove intermediate GTF lookups at
rm -f ${out_path_step043_summary}/gtf-lookup_*.tsv

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
cut -f1 ${input} | sort | uniq | while read stem; do echo 'echo "## Plot results at" ; date ; echo' >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done
cut -f1 ${input} | sort | uniq | while read stem; do rscript=$(col ${stem} 7); rfunctions=$(col ${stem} 8); combined=$(col ${stem} 9); replicates=$(col ${stem} 10); stat=$(col ${stem} 11 | tr 'A-Z' 'a-z'); threshold=$(col ${stem} 12); echo "Rscript ${rscript} --inputgene ${out_path_step043_summary}/${stem}.gene_summary.full.tsv --inputsgrna ${out_path_step043_summary}/${stem}.sgrna_summary.full.tsv --inputcomb ${combined} --inputrep ${replicates} --outdir ${out_path_step043_summary}/ --outstem ${stem} --stat ${stat} --threshold ${threshold} --function ${rfunctions}" >> ${pbs_stem}_${stem}_${thislogdate}.pbs; done

#................................................
#  Submit PBS jobs
#................................................

## Submit PBS jobs 
ls ${pbs_stem}_*${thislogdate}.pbs | while read pbs; do echo ; echo "#................................................" ; echo "# This is PBS: ${pbs}" ;  echo "#" ; echo "# main command line: $(tail -n1 ${pbs})" ; echo "#" ; echo "# now submitting PBS" ; echo "qsub ${pbs}" ; qsub ${pbs} ; echo "#................................................" ; done

date ## Status of all user jobs (including CAMeLS step 043 jobs) at
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
sed -n -e :a -e '1,3!{P;N;D;};N;ba' $logfile > ${logfile}.tmp ; mv ${logfile}.tmp $logfile
set +v