#!/usr/bin/env bash
#SBATCH --job-name="medusa_snpSniff"
#SBATCH --time=0-48:00:00
#SBATCH --mail-user=jetstream@tgen.org
#SBATCH --mail-type=FAIL


time=`date +%d-%m-%Y-%H-%M` 
beginTime=`date +%s`
machine=`hostname`
echo "### NODE: $machine"
echo "### RUNDIR: ${RUNDIR}"
echo "### NXT1: ${NXT1}"
echo "### BAM: ${BAM}"
echo "### REF: ${REF}"
echo "### SNPSNIFFERPATH: ${SNPSNIFFERPATH}"
echo "### SAMTOOLSPATH: ${SAMTOOLSPATH}"
echo "### OUTVCF: ${OUTVCF}"
export PATH=${SNPSNIFFERPATH}:${SAMTOOLSPATH}:${SAMTOOLSPATH}/bcftools/:$PATH
dbIni="/scratch/illumina_run_folders/genotypeInfo/database.ini"

outName=${BAM/.bam}

echo "### Starting snp sniffer on ${BAM}"
echo "### Starting -genotype step"
perf stat /usr/lib/jvm/java-1.7.0-openjdk-1.7.0.91-2.6.2.3.el7.x86_64/jre/bin/java -jar ${SNPSNIFFERPATH}/snpSnifferV5.jar -genotype ${REF} ${BAM} 2> ${BAM}.snpSniffGen.perfOut
if [ $? -eq 0 ] ; then
    touch ${BAM}.snpSniffPass
    mv ${outName}_flt.vcf ${OUTVCF}
else
    echo "### Snp sniffer failed at genotype stage"
    touch ${BAM}.snpSniffFail
    rm ${BAM}.snpSniffInQueue
fi
echo "### Ending -genotype step"
#echo "### Starting -add step"
#perf stat /usr/lib/jvm/java-1.7.0-openjdk-1.7.0.91-2.6.2.3.el7.x86_64/jre/bin/java -jar ${SNPSNIFFERPATH}/snpSnifferV5.jar -add $vcf $dbIni 2> ${BAM}.snpSniffAdd.perfOut
#if [ $? -ne 0 ] ; then
#    echo "### Snp sniffer failed at add stage"
#    touch ${BAM}.snpSniffFail
#else
#    touch ${BAM}.snpSniffPass
#fi
#echo "### Ending -add step"
rm ${BAM}.snpSniffInQueue

endTime=`date +%s`
elapsed=$(( $endTime - $beginTime ))
(( hours=$elapsed/3600 ))
(( mins=$elapsed%3600/60 ))
echo "RUNTIME:SNPSNIFF:$hours:$mins" > ${BAMPRE}.snpSniff.totalTime
time=`date +%d-%m-%Y-%H-%M` 
echo "snp sniff ended at $time"
