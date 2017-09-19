#!/usr/bin/env bash
#SBATCH --job-name="medusa_reduceReads"
#SBATCH --time=0-96:00:00
#SBATCH --mail-user=jetstream@tgen.org
#SBATCH --mail-type=FAIL


time=`date +%d-%m-%Y-%H-%M`
beginTime=`date +%s`
machine=`hostname`
echo "### NODE: $machine"
echo "### REF: ${REF}"
echo "### RUNDIR: ${RUNDIR}"
echo "### NXT1: ${NXT1}"
echo "### GATKPATH: ${GATKPATH}"
echo "### BAMFILE: ${BAMFILE}"

echo "### Reduce reads started for bams at $time."
perf stat java -Djava.io.tmpdir=/scratch/tgenjetstream/tmp/ -jar -Xmx32g ${GATKPATH}/GenomeAnalysisTK.jar \
-R ${REF} \
-T ReduceReads \
-I ${BAMFILE} \
-o ${OUTPUTBAM} > ${BAMFILE}.rrOut 2> ${BAMFILE}.reduceReads.perfOut
if [ $? -eq 0 ] ; then
    mv ${BAMFILE}.rrOut ${BAMFILE}.rrPass
    touch ${RUNDIR}/${NXT1}
else
    mv ${BAMFILE}.rrOut ${BAMFILE}.rrFail
fi
rm -f ${BAMFILE}.rrInQueue

endTime=`date +%s`
elapsed=$(( $endTime - $beginTime ))
(( hours=$elapsed/3600 ))
(( mins=$elapsed%3600/60 ))
echo "RUNTIME:GATKRR:$hours:$mins" > ${TRK}.uniGeno.totalTime

time=`date +%d-%m-%Y-%H-%M`
echo "Reduce reads finished at $time."
