#!/usr/bin/env bash
#SBATCH --job-name="medusa_picHSMetrics"
#SBATCH --time=0-32:00:00
#SBATCH --mail-user=jetstream@tgen.org
#SBATCH --mail-type=FAIL

 
module load R/2.15.2
beginTime=`date +%s`
machine=`hostname`
echo "### NODE: $machine"
echo "### REF: ${REF}"
echo "### BAMFILE: ${BAMFILE}"
echo "### PICARDPATH: ${PICARDPATH}"
echo "### BAITS: ${BAITS}"
echo "### TARGETS: ${TARGETS}"

cd ${DIR}
echo "### Starting picard rna metrics"
echo "perf stat /usr/lib/jvm/java-1.7.0-openjdk-1.7.0.91-2.6.2.3.el7.x86_64/jre/bin/java -Xmx15g -jar ${PICARDPATH}/CalculateHsMetrics.jar \
    REFERENCE_SEQUENCE=${REF} \
    BAIT_INTERVALS=${BAITS} \
    TARGET_INTERVALS=${TARGETS} \
    INPUT=${BAMFILE} \
    OUTPUT=${BAMFILE}.picHSMetrics \
    PER_TARGET_COVERAGE=${BAMFILE}.picStats.HsPerTargetCov \
    TMP_DIR=${TMPDIR} \
    VALIDATION_STRINGENCY=SILENT > ${BAMFILE}.picHSMetricsOut 2> ${BAMFILE}.picardHS.perfOut
"
perf stat /usr/lib/jvm/java-1.7.0-openjdk-1.7.0.91-2.6.2.3.el7.x86_64/jre/bin/java -Xmx15g -jar ${PICARDPATH}/CalculateHsMetrics.jar \
    REFERENCE_SEQUENCE=${REF} \
    BAIT_INTERVALS=${BAITS} \
    TARGET_INTERVALS=${TARGETS} \
    INPUT=${BAMFILE} \
    OUTPUT=${BAMFILE}.picHSMetrics \
    PER_TARGET_COVERAGE=${BAMFILE}.picStats.HsPerTargetCov \
    TMP_DIR=${TMPDIR} \
    VALIDATION_STRINGENCY=SILENT > ${BAMFILE}.picHSMetricsOut 2> ${BAMFILE}.picardHS.perfOut
if [ $? -eq 0 ] ; then
    mv ${BAMFILE}.picHSMetricsOut ${BAMFILE}.picHSMetricsPass
else
    mv ${BAMFILE}.picHSMetricsOut ${BAMFILE}.picHSMetricsFail
fi
rm -f ${BAMFILE}.picHSMetricsInQueue
#a little organizing
if [ -d ${RUNDIR}/stats/ ] ; then
    echo "moving files into stats folder"
    mv ${BAMFILE}.picHSMetrics ${RUNDIR}/stats/
    mv ${BAMFILE}.picHSMetrics.pdf ${RUNDIR}/stats/
    mv ${BAMFILE}.picStats.HsPerTargetCov ${RUNDIR}/stats/
fi
endTime=`date +%s`
elapsed=$(( $endTime - $beginTime ))
(( hours=$elapsed/3600 ))
(( mins=$elapsed%3600/60 ))
echo "RUNTIME:PICHSMET:$hours:$mins" > ${BAMFILE}.picHSMet.totalTime
echo "ending picard HS metrics"
