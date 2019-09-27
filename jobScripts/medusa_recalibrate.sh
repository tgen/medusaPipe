#!/usr/bin/env bash
#SBATCH --job-name="medusa_RC"
#SBATCH --time=0-48:00:00
#SBATCH --mail-user=jetstream@tgen.org
#SBATCH --mail-type=FAIL
#SBATCH --mem-per-cpu 4096

time=`date +%d-%m-%Y-%H-%M` 
beginTime=`date +%s`
machine=`hostname`

echo "### NODE: $machine"
echo "### REF: ${REF}"
echo "### GATK: ${GATKPATH}"
echo "### KNOWN: ${KNOWN}"
echo "gatk base recalibration started on $machine"

perf stat /usr/lib/jvm/java-1.7.0-openjdk-1.7.0.91-2.6.2.3.el7.x86_64/jre/bin/java -Xmx44g -jar ${GATKPATH}/GenomeAnalysisTK.jar \
        -T BaseRecalibrator \
        -nct 8 \
        -l INFO \
        -R ${REF} \
        -knownSites ${KNOWN} \
        -I ${BAMFILE} \
        -cov ReadGroupCovariate \
        -cov QualityScoreCovariate \
        -cov CycleCovariate \
        -cov ContextCovariate \
        --disable_indel_quals \
        -o ${BAMFILE}.recal_data.grp 2> ${BAMFILE}.baseRecal.perfOut > ${BAMFILE}.recalibrateOut
if [ $? -ne 0 ] ; then
    mv ${BAMFILE}.recalibrateOut ${BAMFILE}.recalibrateFail
    echo "recal failed at base recalibrator"
    rm -rf ${BAMFILE}.recalibrateInQueue
    exit 1
fi
echo "gatk base recalibration print reads stage started"
perf stat /usr/lib/jvm/java-1.7.0-openjdk-1.7.0.91-2.6.2.3.el7.x86_64/jre/bin/java -Xmx44g -jar ${GATKPATH}/GenomeAnalysisTK.jar \
        -l INFO \
        -nct 8 \
        -R ${REF} \
        -I ${BAMFILE} \
        -T PrintReads \
        --out ${RECALBAM} \
        -BQSR ${BAMFILE}.recal_data.grp 2> ${BAMFILE}.recalPrint.perfOut >> ${BAMFILE}.recalibrateOut
if [ $? -eq 0 ] ; then
    mv ${BAMFILE}.recalibrateOut ${BAMFILE}.recalibratePass
    echo "Automatically removed by recalibration step to save on space" > ${BAMFILE}
    touch ${RUNDIR}/${NXT1}
else
    mv ${BAMFILE}.recalibrateOut ${BAMFILE}.recalibrateFail
fi
rm -rf ${BAMFILE}.recalibrateInQueue
endTime=`date +%s`
elapsed=$(( $endTime - $beginTime ))
(( hours=$elapsed/3600 ))
(( mins=$elapsed%3600/60 ))
echo "RUNTIME:RECAL:$hours:$mins" > ${BAMFILE}.rc.totalTime
time=`date +%d-%m-%Y-%H-%M` 
echo "gatk recalibration ended"
