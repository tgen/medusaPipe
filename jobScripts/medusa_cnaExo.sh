#!/usr/bin/env bash
#SBATCH --job-name="medusa_cnaExo"
#SBATCH --time=0-48:00:00
#SBATCH --mail-user=jetstream@tgen.org

module load perl/5.24.1
module load MCR/8.3
module load R/3.4.1 ## NEEDS DNAcopy https://bioconductor.org/packages/release/bioc/html/DNAcopy.html
MCRPATH=/packages/MCR/8.3/

#####PBS -l nodes=1:ppn=8
time=`date +%d-%m-%Y-%H-%M`
beginTime=`date +%s`
machine=`hostname`
echo "### NODE: $machine"
echo "### REF: ${REF}"
echo "### NCORES: ${NCORES}"
echo "### CNAPATH: ${CNAPATH}"
echo "### GTF: ${GTF}"
echo "### OFILE: ${OFILE}"
echo "### ASSAY: ${ASSAY}"
echo "### NORMALDAT: ${NORMALDAT}"
echo "### TUMORDAT: ${TUMORDAT}"
echo "### RUNDIR: ${RUNDIR}"
echo "### NHETDEPTH: ${NHETDEPTH}"
echo "### THETDEPTH: ${THETDEPTH}"
echo "### MYPATH: ${MYPATH}"
echo "### MERGEDVCF: ${MERGEDVCF}"

echo "Starting cna at ${MYPATH} at $time."
cd ${MYPATH}

## add error catching for all of the steps
##parse merged VCF
echo "### Start parseMergeVCF.pl"
${CNAPATH}/parseMergeVCF.pl ${MERGEDVCF} ${NORMALSAMPLE} ${TUMORSAMPLE}
echo "### End parseMergeVCF.pl"

##CNA  - Copy Number Analysis (MATLAB)
HETFILE=merged.vcf.txt

smWin=6             #   <<<< THIS CAN BE ADJUSTED - smoothing window size >>>>
fcThresh=0.75       #   <<<< THIS CAN BE ADJUSTED - fold-change threshold - plot >>>>

res=2               #   <<<< THIS CAN BE ADJUSTED - min resolution >>>>
#readDepth=300       #   <<<< THIS CAN BE ADJUSTED - min number of counts >>>>
maxGap=1000   #   <<<< THIS CAN BE ADJUSTED - max distance between consecutive postions >>>>

#hetDepth=100        #   <<<< THIS CAN BE ADJUSTED - min depth of diploid het position >>>>
hetDev=0.05          #   <<<< THIS CAN BE ADJUSTED - allowable deviation from ref allele frequency of 0.5

readDepth=`echo "${NHETDEPTH} * 3" | bc `

echo "### Start run_ngsCNA.sh"
echo "perf stat ${CNAPATH}/run_ngsCNA.sh ${MCRPATH} ${NORMALDAT} ${TUMORDAT} ${OFILE} ${HETFILE} ${smWin} ${fcThresh} ${ASSAY} ${res} ${readDepth} ${maxGap} ${NHETDEPTH} ${THETDEPTH} ${hetDev} ${CNAEXOMETARGET} 2> ${OFILE}.runNgsCna.perfOut"
perf stat ${CNAPATH}/run_ngsCNA.sh ${MCRPATH} ${NORMALDAT} ${TUMORDAT} ${OFILE} ${HETFILE} ${smWin} ${fcThresh} ${ASSAY} ${res} ${readDepth} ${maxGap} ${NHETDEPTH} ${THETDEPTH} ${hetDev} ${CNAEXOMETARGET} 2> ${OFILE}.runNgsCna.perfOut 
if [ $? -ne 0 ] ; then
    echo "### CNA failed at run_ngsCNA.sh"
    touch ${TRACKNAME}.cnaExomeFail
    rm -f ${TRACKNAME}.cnaExomeInQueue
    exit 1
else
    echo "### Renaming cnaStats files"
    nFileName=`basename ${NORMALDAT}`
    tFileName=`basename ${TUMORDAT}`
    mv ${NORMALDAT}.cnaStats ${RUNDIR}/stats/$nFileName.exo.cnaStats
    mv ${TUMORDAT}.cnaStats ${RUNDIR}/stats/$tFileName.exo.cnaStats
    echo "### Renaming/moving cnaStats file is done."
fi
echo "### End run_ngsCNA.sh"

## CBS segmentation
echo "### Start runDNAcopyExome.R"
Rscript --vanilla ${CNAPATH}/runDNAcopyExomeV2.R ${OFILE}.cna.tsv ${OFILE}.seg
if [ $? -ne 0 ] ; then
    echo "### CNA failed at runDNAcopyExome.R"
    touch ${TRACKNAME}.cnaExomeFail
    rm -f ${TRACKNAME}.cnaExomeInQueue
    exit 1
fi

echo "### End runDNAcopyExome.R"
##plotting

Rscript --vanilla ${CNAPATH}/plotCGH_EXOME.R ${OFILE}.cna.tsv ${OFILE}.amp.tsv ${OFILE}.del.tsv ${OFILE}

if [ -f ${OFILE}.hets.tsv ] ; then
    echo "### Running plots with hets"
    Rscript --vanilla ${CNAPATH}/plotCGHwithHets.R ${OFILE}.cna.tsv ${OFILE}.amp.tsv ${OFILE}.del.tsv ${OFILE}.hets.tsv ${OFILE}_withhets
    if [ $? -ne 0 ] ; then
        echo "### CNA failed at plotCGHwithHets.R"
        touch ${TRACKNAME}.cnaExomeFail
        rm -f ${TRACKNAME}.cnaExomeInQueue
        exit 1
    fi

    echo "### End running plots with hets"
fi

##Annotate and convert SEG file to gVCF 
DUPTHRESH=0.58     #   <<<< THIS CAN BE ADJUSTED - Amplification Threshold - log2 fold-change >>>>
DELTHRESH=-0.99    #   <<<< THIS CAN BE ADJUSTED - Deletion Threshold - log2 fold-change >>>>

echo "### Start annotSeg.pl"
${CNAPATH}/annotSeg.pl ${GTF} ${OFILE}.cna.seg ${DUPTHRESH} ${DELTHRESH}
if [ $? -ne 0 ] ; then
    echo "### CNA failed at annotSeg.pl"
    touch ${TRACKNAME}.cnaExomeFail
    rm -f ${TRACKNAME}.cnaExomeInQueue
    exit 1
fi
echo "### End annotSeg.pl"


touch ${TRACKNAME}.cnaExomePass
rm -f ${TRACKNAME}.cnaExomeInQueue
time=`date +%d-%m-%Y-%H-%M`
endTime=`date +%s`
elapsed=$(( $endTime - $beginTime ))
(( hours=$elapsed/3600 ))
(( mins=$elapsed%3600/60 ))
echo "RUNTIME:CNAEXO:$hours:$mins" > ${OFILE}.cnaExo.totalTime
echo "Finished cna exo at $time."