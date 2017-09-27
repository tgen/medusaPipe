#!/usr/bin/env bash
#SBATCH --job-name="medusa_MergeBams"
#SBATCH --time=0-48:00:00
#SBATCH --mail-user=jetstream@tgen.org
#SBATCH --mail-type=FAIL



cd ${RUNDIR}
time=`date +%d-%m-%Y-%H-%M`
beginTime=`date +%s`
machine=`hostname`
echo "### NODE: $machine"
echo "### PICARDPATH: ${PICARDPATH}"
echo "### SAMTOOLSPATH: ${SAMTOOLSPATH}"
echo "### CNT: ${CNT}"
echo "### RUNDIR: ${RUNDIR}"
echo "### MERGEDBAM: ${MERGEDBAM}"
echo "### BAMLIST: ${BAMLIST}"
echo "### NXT1: ${NXT1}"

echo "### TIME:$time starting picard merge bams to create ${MERGEDBAM}"

onlyBamFile=${BAMLIST/I=/}
onlyBaiFile=${onlyBamFile/.bam/.bai}
mergedBai=${MERGEDBAM/.bam/.bai}

if [ ${CNT} -eq 1 ] ; then #nothing really merged, only copied
    echo "### Just copying $onlyBamFile to ${MERGEDBAM}" > ${MERGEDBAM}.mergeBamOut
    cp $onlyBaiFile $mergedBai
    perf stat cp $onlyBamFile ${MERGEDBAM} 2> ${MERGEDBAM}.mergeBam.perfOut
    if [ $? -ne 0 ] ; then #bad cp
        mv ${MERGEDBAM}.mergeBamOut ${MERGEDBAM}.mergeBamFail
    else #good cp
        mv ${MERGEDBAM}.mergeBamOut ${MERGEDBAM}.mergeBamPass
        echo "Automatically removed by merge bam step to save on space" > $onlyBamFile
        touch ${RUNDIR}/${NXT1}
    fi
else #actually merged with picard
    perf stat /usr/lib/jvm/java-1.7.0-openjdk-1.7.0.91-2.6.2.3.el7.x86_64/jre/bin/java -Xmx42g -jar ${PICARDPATH}/MergeSamFiles.jar ASSUME_SORTED=true USE_THREADING=true VALIDATION_STRINGENCY=SILENT TMP_DIR=${TMPDIR} OUTPUT=${MERGEDBAM} ${BAMLIST} 2> ${MERGEDBAM}.mergeBam.perfOut > ${MERGEDBAM}.mergeBamOut
    if [ $? -ne 0 ] ; then #bad merge
        mv ${MERGEDBAM}.mergeBamOut ${MERGEDBAM}.mergeBamFail
    else #good merge
        echo "### Starting indexing of bam with samtools now that merge finished OK"
        perf stat ${SAMTOOLSPATH}/samtools index ${MERGEDBAM} 2> ${MERGEDBAM}.samindex.perfOut
        mv ${MERGEDBAM}.bai $mergedBai
        echo "### Ended indexing of bam after merging."
        mv ${MERGEDBAM}.mergeBamOut ${MERGEDBAM}.mergeBamPass
        for bam in ${BAMLIST}
        do
            bamPath=`echo $bam | cut -d= -f2`
            echo "Automatically removed by merge bam step to save on space" > $bamPath
        done
        touch ${RUNDIR}/${NXT1}
    fi
fi
rm ${MERGEDBAM}.mergeBamInQueue
endTime=`date +%s`
elapsed=$(( $endTime - $beginTime ))
(( hours=$elapsed/3600 ))
(( mins=$elapsed%3600/60 ))
echo "RUNTIME:MERGEBAMS:$hours:$mins" > ${MERGEDBAM}.mergeBam.totalTime

time=`date +%d-%m-%Y-%H-%M`
echo "TIME:$time picard merge bams finished"
