#!/usr/bin/env bash
#PBS -S /bin/bash
#SBATCH --job-name="medusa_mergeVCFs"
#SBATCH --time=0-24:00:00
#SBATCH --mail-user=jetstream@tgen.org
#SBATCH --mail-type=FAIL
#PBS -j oe
#SBATCH --output="/${D}/oeFiles/${PBS_JOBNAME}_${PBS_JOBID}.out"
#SBATCH --error="/${D}/oeFiles/${PBS_JOBNAME}_${PBS_JOBID}.err"
 
time=`date +%d-%m-%Y-%H-%M`
beginTime=`date +%s`
machine=`hostname`
echo "### NODE: $machine"
echo "### RUNDIR: ${RUNDIR}"
echo "### NXT1: ${NXT1}"
echo "### NXT2: ${NXT2}"
echo "### NXT3: ${NXT3}"
echo "### FILELIST: ${FILELIST}"

echo "### TIME:$time starting to merge vcfs to create ${MERGEDVCF}"

vcfCount=1
for line in `echo ${FILELIST}`
do
    thisVCF=${line/I=/}
    echo "$vcfCount: $thisVCF"
    if [ $vcfCount -eq 1 ] ; then
        cat $thisVCF > ${MERGEDVCF}
    else
        cat $thisVCF | grep -v "^#" >> ${MERGEDVCF}
    fi
    ((vcfCount++))
done
if [ $? -ne 0 ] ; then #bad merge
    #mv ${MERGEDVCF}.mergeVcfOut ${MERGEDVCF}.mergeVcfFail
    touch ${MERGEDVCF}.mergeVcfFail
else #good merge
    #mv ${MERGEDVCF}.mergeVcfOut ${MERGEDVCF}.mergeVcfPass
    touch ${MERGEDVCF}.mergeVcfPass
    touch ${RUNDIR}/${NXT1}
    touch ${RUNDIR}/${NXT2}
    touch ${RUNDIR}/${NXT3}
fi
rm ${MERGEDVCF}.mergeVcfInQueue
endTime=`date +%s`
elapsed=$(( $endTime - $beginTime ))
(( hours=$elapsed/3600 ))
(( mins=$elapsed%3600/60 ))
echo "RUNTIME:MERGEVCFS:$hours:$mins" > ${MERGEDVCF}.mergeVcf.totalTime

time=`date +%d-%m-%Y-%H-%M`
echo "TIME:$time Merge vcfs finished"
