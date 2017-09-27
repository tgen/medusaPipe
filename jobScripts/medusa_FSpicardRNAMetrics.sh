#!/usr/bin/env bash
#SBATCH --job-name="medusa_FSpicRNAMetrics"
#SBATCH --time=0-32:00:00
#SBATCH --mail-user=jetstream@tgen.org
#SBATCH --mail-type=FAIL

module load R/2.15.2
beginTime=`date +%s`
machine=`hostname`
echo "### NODE: $machine"
echo "### REF: ${REF}"
echo "### REFFLAT: ${REFFLAT}"
echo "### RIBINTS: ${RIBINTS}"
echo "### BAMFILE: ${BAMFILE}"
echo "### PICARDPATH: ${PICARDPATH}"

echo "### Starting first stranded picard rna metrics"
perf stat /usr/lib/jvm/java-1.7.0-openjdk-1.7.0.91-2.6.2.3.el7.x86_64/jre/bin/java -Xmx15g -Djava.io.tmpdir=${TMPDIR} -jar ${PICARDPATH}/CollectRnaSeqMetrics.jar \
    REF_FLAT=${REFFLAT} \
    REFERENCE_SEQUENCE=${REF} \
    RIBOSOMAL_INTERVALS=${RIBINTS} \
    STRAND_SPECIFICITY=FIRST_READ_TRANSCRIPTION_STRAND \
    INPUT=${BAMFILE} \
    OUTPUT=${BAMFILE}.picRNAMetrics \
    CHART_OUTPUT=${BAMFILE}.picRNAMetrics.pdf \
    TMP_DIR=${TMPDIR} \
    VALIDATION_STRINGENCY=SILENT > ${BAMFILE}.picRNAMetricsOut 2> ${BAMFILE}.picardRNA.perfOut
if [ $? -eq 0 ] ; then
    mv ${BAMFILE}.picRNAMetricsOut ${BAMFILE}.picRNAMetricsPass
else
    mv ${BAMFILE}.picRNAMetricsOut ${BAMFILE}.picRNAMetricsFail
fi
rm -f ${BAMFILE}.picRNAMetricsInQueue
#a little organizing
if [ -d ${RUNDIR}/stats/ ] ; then
    echo "moving files into stats folder"
    mv ${BAMFILE}.picRNAMetrics ${RUNDIR}/stats/
    mv ${BAMFILE}.picRNAMetrics.pdf ${RUNDIR}/stats/
fi
endTime=`date +%s`
elapsed=$(( $endTime - $beginTime ))
(( hours=$elapsed/3600 ))
(( mins=$elapsed%3600/60 ))
echo "RUNTIME:PICRNAMET:$hours:$mins" > ${BAMFILE}.picRnaMet.totalTime
echo "ending picard rna metrics"
