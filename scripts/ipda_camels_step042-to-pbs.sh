#!/bin/bash
version="1.1.0"
usage(){
echo "
Written by Isabela Almeida
Created on September 26, 2025
Last modified on Nov 18, 2026
Version: ${version}

Description: Run Step 042 of the CAMeLS pipeline (CRISPR Analysis Method for Library Screens). 

Usage: bash ipda_camels_step042-to-pbs.sh -i 'path/to/input/files'

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
                            library-filtering-stem (run name; letters, digits, . _ - only).
                            For example:
                            riskoc-FDR0p1 for library riskoc filtered at FDR 0.1 (col8 fdr, col9 0.1)
                            riskoc-pval0p05 for library riskoc filtered at p-value 0.05 (col8 pval, col9 0.05)

                            Col7:
                            /path/from/working/dir/to/targets-info.tsv
                            containing
                            chr \t start \t end \t id \t score \t strand \t type \t name \t ucsc-location \t notes

                            Col8:
                            <fdr|pval>
                            Which statistic to use for calling significant hits
                            fdr  -> pos col 11 (pos|fdr),     neg col 5 (neg|fdr)
                            pval -> pos col 10 (pos|p-value), neg col 4 (neg|p-value)

                            Col9:
                            FLOAT
                            Threshold for calling significant hits
                            (genes kept if statistic < threshold)

                            Col8 and Col9 must be the same on every
                            row that shares the same Col6 run name.
                            The same Col1 file can appear in several
                            runs. Rows sharing Col1 and Col6 must also
                            share Cols 2-5 and 7. Exact duplicate rows
                            are ignored.

## Output:

logfile.txt                                       Logfile with commands executed and date
<run>_<celltype>_<stem>.pos|neg.gene_summary.txt  Genes passing the threshold (pos/neg)
<...>.gene_summary.posctrl|negctrl|targets.txt    Controls/targets among those genes
<...>.gene_summary.targets.info.tsv               Col7 info rows for significant targets,
                                                  with their FDR or p-value appended
summary_hits-stats-<run>.tsv                      Hit counts per cell type/normalisation

Pipeline description:

#   010 Quality check sequencing (1FastQC, 2MultiQC)
#   020 Guide representation (1BBDuk - finds 23nt perfect matchs and 21nt 0,2 and 3MM, 2BASH - write to TSV, 3R plot results)
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
while getopts "i:h:v" flag
do
    case "${flag}" in
        i) input="${OPTARG}";;       # Input files including path
        h) Help ; exit;;             # Print Help and exit
        v) echo "${version}"; exit;; # Print version and exit
        ?) echo "script usage: bash ipda_camels_step042-to-pbs.sh -i path/to/input/file.tsv" >&2
           exit;;
    esac
done

#................................................
#  Validate statistic/threshold columns (8, 9)
#................................................

awk -F'\t' '
{
    s = tolower($8); t = $9
    if ($6 !~ /^[A-Za-z0-9._-]+$/) { print "ERROR line " NR ": col6 must contain only letters, digits, . _ - (got \"" $6 "\")" > "/dev/stderr"; bad = 1 }
    if (s != "fdr" && s != "pval") { print "ERROR line " NR ": col8 must be fdr or pval (got \"" $8 "\")" > "/dev/stderr"; bad = 1 }
    if (!(t+0 == t && t > 0 && t <= 1)) { print "ERROR line " NR ": col9 must be a number in (0,1] (got \"" t "\")" > "/dev/stderr"; bad = 1 }
    if (($6 in S) && (S[$6] != s || T[$6] != t)) { print "ERROR line " NR ": conflicting col8/col9 for run " $6 > "/dev/stderr"; bad = 1 }
    S[$6] = s; T[$6] = t
}
END { exit bad }' ${input} || exit 1

#................................................
#  Helpers
#................................................

## Unique input rows (cols 1-9, statistic lowercased)
## Each line it prints is one row to process
list_runs(){ awk -F'\t' -v OFS='\t' '{print $1,$2,$3,$4,$5,$6,$7,tolower($8),$9}' ${input} | sort -u; }

## Usage: set_stat_vars "fdr|pval" "threshold"
## Sets: stat, threshold, poscol, negcol, label
set_stat_vars(){
    stat="$1"; threshold="$2"
    case "${stat}" in
        fdr)  poscol=11; negcol=5; label="FDR";;
        pval) poscol=10; negcol=4; label="pval";;
        *)    echo "ERROR: unknown statistic '${stat}'" >&2; exit 1;;
    esac
}

## Count data lines in a file (skip header if $2=1); 0 if file missing/empty
count_hits(){ if [ -s "$1" ]; then awk -v h="$2" 'FNR>h{n++} END{print n+0}' "$1"; else echo 0; fi; }

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
out_path_step042_summary="camels042_sig-hits_summary_${thislogdate}"

## Create output directories
mkdir -p ${out_path_step042_summary}

#................................................
#  Print Execution info to user
#................................................

date
echo "## Executing bash ipda_camels_step042-to-pbs.sh"
echo "## This execution PID: ${pid}"
echo
echo "## Given input file:            ${input}"
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
echo "## Given input file:            ${input}"
echo
echo "## Outputs created:"
echo
echo "## Output files saved to:       ${out_path_step042_summary}"
echo "## This is logfile:             ${logfile}"

set -v

#................................................
#  Filter results passing threshold
#................................................

date ## Filter genes passing user-defined significance threshold at
list_runs | while IFS=$'\t' read -r file celltype negative positive target run info stat threshold; do
    stem=$(echo ${file} | rev | cut -d'/' -f1 | cut -d'.' -f3- | rev | cut -d'_' -f2)
    set_stat_vars "${stat}" "${threshold}"
    base=${out_path_step042_summary}/${run}_${celltype}_${stem}
    echo "## ${run} ${celltype}_${stem}: stat=${stat} threshold=${threshold} pos-col=${poscol} neg-col=${negcol}"
    awk -F'\t' -v c=${poscol} -v t=${threshold} 'NR==1 || $c < t' ${file} > ${base}.pos.gene_summary.txt
    awk -F'\t' -v c=${negcol} -v t=${threshold} 'NR==1 || $c < t' ${file} > ${base}.neg.gene_summary.txt
done

date ## Identify pos/neg/target hits passing significance threshold at
while IFS=$'\t' read -r file celltype negative positive target run info stat threshold; do
    stem=$(echo ${file} | rev | cut -d'/' -f1 | cut -d'.' -f3- | rev | cut -d'_' -f2)
    set_stat_vars "${stat}" "${threshold}"
    base=${out_path_step042_summary}/${run}_${celltype}_${stem}
    while read stats; do
        mainstats=$(echo "${stats}" | rev | cut -d'/' -f1 | cut -d'.' -f2- | rev)
        grep -wFf ${positive} ${stats} > ${out_path_step042_summary}/${mainstats}.posctrl.txt || true
        grep -wFf ${negative} ${stats} > ${out_path_step042_summary}/${mainstats}.negctrl.txt || true
        grep -wFf ${target}   ${stats} > ${out_path_step042_summary}/${mainstats}.targets.txt || true

        ## Subset targets-info to the significant targets, appending their statistic
        case ${mainstats} in
            *.pos.gene_summary) c=${poscol};;
            *.neg.gene_summary) c=${negcol};;
        esac
        {
            echo -e "chr\tstart\tend\tid\tscore\tstrand\ttype\tname\tucsc-location\tnotes\t${label}"
            awk -F'\t' -v c=${c} 'NR==FNR{v[$1]=$c; next} ($4 in v){print $0"\t"v[$4]}' \
                ${out_path_step042_summary}/${mainstats}.targets.txt ${info}
        } > ${out_path_step042_summary}/${mainstats}.targets.info.tsv
    done < <(ls ${base}.*.gene_summary.txt)
done < <(list_runs)

date ## Write summary counts of significant hits to TSV at
list_runs | while IFS=$'\t' read -r file celltype negative positive target run info stat threshold; do
    stem=$(echo ${file} | rev | cut -d'/' -f1 | cut -d'.' -f3- | rev | cut -d'_' -f2)
    set_stat_vars "${stat}" "${threshold}"
    base=${out_path_step042_summary}/${run}_${celltype}_${stem}
    summary=${out_path_step042_summary}/summary_hits-stats-${run}.tsv

    ## write header once per run
    [ -s "${summary}" ] || echo -e "cell-type\tnormalisation\tstatistic\tthreshold\tgene-counts\tall-hits\tpos-hits\tneg-hits" > ${summary}

    for grp in all-genes:: pos-ctrls:.posctrl: neg-ctrls:.negctrl: targets:.targets:; do
        name=$(echo ${grp} | cut -d':' -f1)
        suf=$(echo ${grp} | cut -d':' -f2)
        hdr=$([ -z "${suf}" ] && echo 1 || echo 0)   # only gene_summary files have a header
        pos=$(count_hits ${base}.pos.gene_summary${suf}.txt ${hdr})
        neg=$(count_hits ${base}.neg.gene_summary${suf}.txt ${hdr})
        echo -e "${celltype}\t${stem}\t${label}\t${threshold}\t${name}\t$((pos+neg))\t${pos}\t${neg}" >> ${summary}
    done
done

# This will remove $VARNAMES from output file with the actual $VARVALUE
# allowing for easily retracing commands
sed -i 's,${input},'"${input}"',g' "$logfile"
sed -i 's,${human_thislogdate},'"${human_thislogdate}"',g' "$logfile"
sed -i 's,${thislogdate},'"${thislogdate}"',g' "$logfile"
sed -i 's,${user},'"${user}"',g' "$logfile"
sed -i 's,${out_path_step042_summary},'"${out_path_step042_summary}"',g' "$logfile"
sed -i 's,${logfile},'"${logfile}"',g' "$logfile"
sed -n -e :a -e '1,3!{P;N;D;};N;ba' $logfile > tmp ; mv tmp $logfile
set +v