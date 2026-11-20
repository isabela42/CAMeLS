#!/bin/bash
version="1.1.0"
usage(){
echo "
Written by Isabela Almeida
Created on September 26, 2025
Last modified on Nov 20, 2026
Version: ${version}

Description: Run Step 042 of the CAMeLS pipeline (CRISPR Analysis Method for Library Screens). 

Usage: bash ipda_camels_step042-to-pbs.sh -i 'path/to/input/files'

## Input:

-i <path/to/input/files>    Input TSV files including path FROM working
                            directory. This TSV file should contain no header line and:
                            
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

                            Col7 (optional, may be left empty):
                            /path/from/working/dir/to/targets.gtf
                            Plain-text GTF used to annotate significant hits. Hit IDs are matched to the gene_id,
                            gene_name or transcript_id attribute. If the GTF is not provided, the annotation columns
                            will be filled with NA.

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
<run>_<celltype>_<stem>.pos|neg.gene_summary.txt  Genes passing the threshold (pos/neg): MAGeCK columns
                                                  plus chr, start, end, strand, type, name,
                                                  ucsc-location (NA if no GTF) and category
<...>.gene_summary.posctrl|negctrl|targets.txt    Controls/targets among those genes
sig-hits-info.tsv                                 One row per significant gene across ALL rows of the
                                                  input TSV; score = number of selections,
                                                  selection-pos/-neg = every run/threshold that selected
                                                  it in each direction
summary_hits-stats-<run>.tsv                      Hit counts per cell type/normalisation

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
#  Validate input file and columns
#................................................

if [ -z "${input}" ] || [ ! -f "${input}" ]; then
    echo "ERROR: input TSV (-i) not given or not found: ${input}" >&2; exit 1
fi

awk -F'\t' '
function missing(f,   line, r) { r = (getline line < f); close(f); return (r < 0) }
{
    s = tolower($8); t = $9
    if ($6 !~ /^[A-Za-z0-9._-]+$/) { print "ERROR line " NR ": col6 must contain only letters, digits, . _ - (got \"" $6 "\")" > "/dev/stderr"; bad = 1 }
    if (s != "fdr" && s != "pval") { print "ERROR line " NR ": col8 must be fdr or pval (got \"" $8 "\")" > "/dev/stderr"; bad = 1 }
    if (!(t+0 == t && t > 0 && t <= 1)) { print "ERROR line " NR ": col9 must be a number in (0,1] (got \"" t "\")" > "/dev/stderr"; bad = 1 }
    if (($6 in S) && (S[$6] != s || T[$6] != t)) { print "ERROR line " NR ": conflicting col8/col9 for run " $6 > "/dev/stderr"; bad = 1 }
    S[$6] = s; T[$6] = t
    for (i = 1; i <= 6; i++) if ($i == "") { print "ERROR line " NR ": col" i " is empty" > "/dev/stderr"; bad = 1 }
    split("1 3 4 5 7", fc, " ")
    for (j in fc) { i = fc[j]; if ($i != "" && missing($i)) { print "ERROR line " NR ": col" i " file not found: " $i > "/dev/stderr"; bad = 1 } }
}
END { exit bad }' ${input} || exit 1

#................................................
#  Helpers
#................................................

## Fields joined with \037 (not tab) so empty columns are kept by read
list_runs(){ awk -F'\t' -v OFS='\037' '{print $1,$2,$3,$4,$5,$6,$7,tolower($8),$9}' ${input} | sort -u; }

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

## Usage: gtf_lookup "path/to/targets.gtf"
## Prints one line per gene_id / gene_name / transcript_id:
## id chr start end strand type name ucsc-location
## (start/end span all GTF lines of that id; coordinates 1-based as in the GTF)
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

## Long table of every significant gene in every run (filled in by the filtering loop)
allhits=${out_path_step042_summary}/sig-hits_all-runs.tmp
echo -e "id\tcategory\trun\tcell-type\tnormalisation\tdirection\tstatistic\tvalue\tthreshold\tchr\tstart\tend\tstrand\ttype\tname\tucsc-location" > ${allhits}

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

date ## Build one id-to-coordinates lookup per GTF (col7) at
while read gtf; do
    gtf_lookup ${gtf} > ${out_path_step042_summary}/gtf-lookup_$(echo "${gtf}" | cksum | cut -d' ' -f1).tsv
done < <(list_runs | awk -F'\037' '$7 != "" && !seen[$7]++ {print $7}')

date ## Filter genes passing user-defined significance threshold at
list_runs | while IFS=$'\037' read -r file celltype negative positive target run info stat threshold; do
    stem=$(echo ${file} | rev | cut -d'/' -f1 | cut -d'.' -f3- | rev | cut -d'_' -f2)
    set_stat_vars "${stat}" "${threshold}"
    base=${out_path_step042_summary}/${run}_${celltype}_${stem}
    echo "## ${run} ${celltype}_${stem}: stat=${stat} threshold=${threshold} pos-col=${poscol} neg-col=${negcol}"

    # Lookup for this row's GTF (none if col7 is empty)
    if [ -n "${info}" ]; then lookup=${out_path_step042_summary}/gtf-lookup_$(echo "${info}" | cksum | cut -d' ' -f1).tsv; else lookup=/dev/null; fi
    
    # Filter, annotate and record significant genes in each direction
    for dir in pos neg; do
        [ ${dir} = pos ] && c=${poscol} || c=${negcol}
        awk -F'\t' -v OFS='\t' -v c=${c} -v t=${threshold} -v dir=${dir} -v run=${run} -v ct=${celltype} -v norm=${stem} -v lab=${label} -v long=${allhits} '
            ## Ensembl IDs are matched to the GTF without their version suffix (ENST00000427076.5 -> ENST00000427076)
            function unver(x) { if (x ~ /^ENS[A-Z]*[0-9]+\.[0-9]+$/) sub(/\.[0-9]+$/, "", x); return x }
            FILENAME==ARGV[1] {P[$1]; next}
            FILENAME==ARGV[2] {N[$1]; next}
            FILENAME==ARGV[3] {T[$1]; next}
            FILENAME==ARGV[4] {L[unver($1)] = $2 OFS $3 OFS $4 OFS $5 OFS $6 OFS $7 OFS $8; next}
            FNR==1 {print $0, "chr", "start", "end", "strand", "type", "name", "ucsc-location", "category"; next}
            $c < t {
                cat = ($1 in P) ? "pos-ctrl" : ($1 in N) ? "neg-ctrl" : ($1 in T) ? "target" : "other"
                k = unver($1)
                ann = (k in L) ? L[k] : "NA" OFS "NA" OFS "NA" OFS "NA" OFS "NA" OFS "NA" OFS "NA"
                print $0, ann, cat
                print $1, cat, run, ct, norm, dir, lab, $c, t, ann >> long
            }' ${positive} ${negative} ${target} ${lookup} ${file} > ${base}.${dir}.gene_summary.txt
    done
done

date ## Identify pos/neg/target hits passing significance threshold at
while IFS=$'\037' read -r file celltype negative positive target run info stat threshold; do
    stem=$(echo ${file} | rev | cut -d'/' -f1 | cut -d'.' -f3- | rev | cut -d'_' -f2)
    set_stat_vars "${stat}" "${threshold}"
    base=${out_path_step042_summary}/${run}_${celltype}_${stem}
    while read stats; do
        mainstats=$(echo "${stats}" | rev | cut -d'/' -f1 | cut -d'.' -f2- | rev)
        awk -F'\t' 'NR==FNR{L[$1]; next} FNR>1 && ($1 in L)' ${positive} ${stats} > ${out_path_step042_summary}/${mainstats}.posctrl.txt
        awk -F'\t' 'NR==FNR{L[$1]; next} FNR>1 && ($1 in L)' ${negative} ${stats} > ${out_path_step042_summary}/${mainstats}.negctrl.txt
        awk -F'\t' 'NR==FNR{L[$1]; next} FNR>1 && ($1 in L)' ${target}   ${stats} > ${out_path_step042_summary}/${mainstats}.targets.txt
    done < <(ls ${base}.*.gene_summary.txt)
done < <(list_runs)

date ## Combine significant hits from all runs into one file at
{
    echo -e "chr\tstart\tend\tid\tscore\tstrand\ttype\tname\tucsc-location\tcategory\tselection-pos\tselection-neg"
    awk -F'\t' -v OFS='\t' '
        NR > 1 {
            id = $1
            if (!(id in CAT)) { CAT[id] = $2; order[++m] = id }
            else if (index(";" CAT[id] ";", ";" $2 ";") == 0) CAT[id] = CAT[id] ";" $2
            if (!(id in ANN) && $10 != "NA") ANN[id] = $10 OFS $11 OFS $12 OFS $13 OFS $14 OFS $15 OFS $16
            sel = $3 "/" $4 "/" $5 " " $7 "=" $8 "<" $9
            if ($6 == "pos") SELP[id] = SELP[id] (SELP[id] == "" ? "" : "; ") sel
            else             SELN[id] = SELN[id] (SELN[id] == "" ? "" : "; ") sel
            CNT[id]++
        }
        END {
            for (x = 1; x <= m; x++) {
                id = order[x]
                sp = (SELP[id] == "") ? "NA" : SELP[id]
                sn = (SELN[id] == "") ? "NA" : SELN[id]
                if (id in ANN) { split(ANN[id], f, "\t"); print f[1], f[2], f[3], id, CNT[id], f[4], f[5], f[6], f[7], CAT[id], sp, sn }
                else           print "NA", "NA", "NA", id, CNT[id], "NA", "NA", "NA", "NA", CAT[id], sp, sn
            }
        }' ${allhits} | sort -t$'\t' -k1,1V -k2,2n | awk '/^NA\t/{na = na $0 "\n"; next} {print} END{printf "%s", na}'
} > ${out_path_step042_summary}/sig-hits-info.tsv

date ## Write summary counts of significant hits to TSV at
list_runs | while IFS=$'\037' read -r file celltype negative positive target run info stat threshold; do
    stem=$(echo ${file} | rev | cut -d'/' -f1 | cut -d'.' -f3- | rev | cut -d'_' -f2)
    set_stat_vars "${stat}" "${threshold}"
    base=${out_path_step042_summary}/${run}_${celltype}_${stem}
    summary=${out_path_step042_summary}/summary_hits-stats-${run}.tsv
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

date ## Remove intermediate files at
rm -f ${out_path_step042_summary}/gtf-lookup_*.tsv ${allhits}

# This will remove $VARNAMES from output file with the actual $VARVALUE
# allowing for easily retracing commands
sed -i 's,${input},'"${input}"',g' "$logfile"
sed -i 's,${human_thislogdate},'"${human_thislogdate}"',g' "$logfile"
sed -i 's,${thislogdate},'"${thislogdate}"',g' "$logfile"
sed -i 's,${user},'"${user}"',g' "$logfile"
sed -i 's,${out_path_step042_summary},'"${out_path_step042_summary}"',g' "$logfile"
sed -i 's,${logfile},'"${logfile}"',g' "$logfile"
sed -n -e :a -e '1,3!{P;N;D;};N;ba' $logfile > ${logfile}.tmp ; mv ${logfile}.tmp $logfile
set +v