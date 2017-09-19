#!/usr/bin/env bash
#PBS -S /bin/bash
#SBATCH --job-name="medusa_revstrandhtSeq4Star"
#SBATCH --time=0-48:00:00
#SBATCH --mail-user=jetstream@tgen.org
#SBATCH --mail-type=FAIL
#PBS -j oe
#SBATCH --output="/${D}/oeFiles/${PBS_JOBNAME}_${PBS_JOBID}.out"
#SBATCH --error="/${D}/oeFiles/${PBS_JOBNAME}_${PBS_JOBID}.err"

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
#perf stat java -Xmx15g -jar ${PICARDPATH}/SortSam.jar TMP_DIR=/scratch/tgenjetstream/tmp/ INPUT=${BAM} OUTPUT=${SAM} SORT_ORDER=queryname 2>${SAM}.picardSort.perfOut
#echo "### Picard sort is done, now starting htseq"
#echo "### First converting BAM to SAM"
#perf stat ${SAMTOOLSPATH}/samtools view -h ${BAM} > ${SAM} 2> ${BAM}.bam2sam.perfOut
echo "### Now running htseq on SAM"
perf stat htseq-count -q --stranded=reverse --mode=union ${SAM} ${GTF} 2> ${SAM}.htseq.perfOut > ${DIR}/${anotherName}.htSeqCounts
if [ $? -eq 0 ] ; then
    touch ${SAM}.htSeqPass
    #touch ${RUNDIR}/${NXT1}
    echo "Deleted by htSeq to save on space at $time" > ${SAM}
else
    touch ${SAM}.htSeqFail
fi
rm -f ${SAM}.htSeqInQueue
time=`date +%d-%m-%Y-%H-%M`
endTime=`date +%s`
elapsed=$(( $endTime - $beginTime ))
(( hours=$elapsed/3600 ))
(( mins=$elapsed%3600/60 ))
echo "RUNTIME:HTSEQ:$hours:$mins" > ${SAM}.htSeq.totalTime

echo "TIME:$time finished htseq on ${BAM}"
