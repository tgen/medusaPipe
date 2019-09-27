#!/usr/bin/env bash
#SBATCH --job-name="medusa_htSeq"
#SBATCH --time=0-96:00:00
#SBATCH --mail-user=jetstream@tgen.org
#SBATCH --mail-type=FAIL
#SBATCH --mem-per-cpu 4096

module load python/2.7.3
#module load HTSeq/0.5.3p9

beginTime=`date +%s`
time=`date +%d-%m-%Y-%H-%M`
machine=`hostname`
echo "### NODE: $machine"
echo "### RUNDIR: ${RUNDIR}"
echo "### NXT1: ${NXT1}"
echo "### PICARDPATH: ${PICARDPATH}"
echo "### BAM: ${BAM}"
echo "### SAM: ${SAM}"

base=`basename ${SAM}`
anotherName=${base/.proj.Aligned.out.sam}
DIR=$(dirname "${SAM}")
#echo "### TIME:$time starting htseq on ${BAM}"
#perf stat /usr/lib/jvm/java-1.7.0-openjdk-1.7.0.91-2.6.2.3.el7.x86_64/jre/bin/java -Xmx15g -jar ${PICARDPATH}/SortSam.jar TMP_DIR=${TMPDIR} INPUT=${BAM} OUTPUT=${SAM} SORT_ORDER=queryname 2>${SAM}.picardSort.perfOut
echo "### Picard sort is done, now starting htseq"

perf stat htseq-count -q --format=bam --stranded=no --mode=union ${BAM} ${GTF} 2> ${SAM}.htseq.perfOut > ${DIR}/${anotherName}.htSeqCounts
if [ $? -eq 0 ] ; then
 
    touch ${SAM}.htSeqPass
    #touch ${RUNDIR}/${NXT1}
else
    mv ${SAM}.htSeqOut ${SAM}.htSeqFail
fi
rm -f ${SAM}.htSeqInQueue
time=`date +%d-%m-%Y-%H-%M`
endTime=`date +%s`
elapsed=$(( $endTime - $beginTime ))
(( hours=$elapsed/3600 ))
(( mins=$elapsed%3600/60 ))
echo "RUNTIME:HTSEQ:$hours:$mins" > ${SAM}.htSeq.totalTime

echo "TIME:$time finished htseq on ${BAM}"
