#!/usr/bin/env bash
#SBATCH --job-name="medusa_picGCMtrcs"
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

cd ${DIR}
echo "### Starting picard gc bias metrics"
#perf stat /usr/lib/jvm/java-1.7.0-openjdk-1.7.0.91-2.6.2.3.el7.x86_64/jre/bin/java -Xmx15g -jar ${PICARDPATH}/CollectAlignmentSummaryMetrics.jar \
    #OUTPUT=${BAMFILE}.picGcBiasMetrics \
perf stat /usr/lib/jvm/java-1.7.0-openjdk-1.7.0.91-2.6.2.3.el7.x86_64/jre/bin/java -Xmx15g -jar ${PICARDPATH}/CollectGcBiasMetrics.jar \
    REFERENCE_SEQUENCE=${REF} \
    INPUT=${BAMFILE} \
    OUTPUT=${BAMFILE}.picGcBiasMetrics \
    CHART_OUTPUT=${BAMFILE}.picGcBiasMetrics.pdf \
    SUMMARY_OUTPUT=${BAMFILE}.picGcBiasMetrics.summary \
    TMP_DIR=${TMPDIR} \
    ASSUME_SORTED=true \
    VALIDATION_STRINGENCY=SILENT > ${BAMFILE}.picGcBiasMetricsOut 2> ${BAMFILE}.picardGcBias.perfOut
if [ $? -eq 0 ] ; then
    mv ${BAMFILE}.picGcBiasMetricsOut ${BAMFILE}.picGcBiasMetricsPass
else
    mv ${BAMFILE}.picGcBiasMetricsOut ${BAMFILE}.picGcBiasMetricsFail
fi
rm -f ${BAMFILE}.picGcBiasMetricsInQueue
#a little organizing
if [ -d ${RUNDIR}/stats/ ] ; then
    echo "### Moving files into stats folder"
    mv ${BAMFILE}.picGcBiasMetrics ${RUNDIR}/stats/
    mv ${BAMFILE}.picGcBiasMetrics.* ${RUNDIR}/stats/
fi
endTime=`date +%s`
elapsed=$(( $endTime - $beginTime ))
(( hours=$elapsed/3600 ))
(( mins=$elapsed%3600/60 ))
echo "RUNTIME:PICGCBIASMET:$hours:$mins" > ${BAMFILE}.picGcBiasMet.totalTime
echo "### Ending picard GC Bias metrics"