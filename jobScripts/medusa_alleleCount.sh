#!/usr/bin/env bash
#PBS -S /bin/bash
#SBATCH --job-name="medusa_alleleCount"
#SBATCH --time=0-48:00:00
#SBATCH --mail-user=jetstream@tgen.org
#SBATCH --mail-type=FAIL
#PBS -j oe
#SBATCH --output="/${D}/oeFiles/${PBS_JOBNAME}_${PBS_JOBID}.out"
#SBATCH --error="/${D}/oeFiles/${PBS_JOBNAME}_${PBS_JOBID}.err"
 
cd ${RUNDIR}
beginTime=`date +%s`
machine=`hostname`
echo "### NODE: $machine"
echo "### REF: ${REF}"
echo "### ALCOUNTPATH: ${ALCOUNTPATH}"
echo "### DNABAM: ${DNABAM}"
echo "### RNABAM: ${RNABAM}"
echo "### VCF: ${VCF}"
echo "### OUT: ${OUT}"
echo "### TRACK: ${TRACK}"

echo "### Starting allele count"
perf stat ${ALCOUNTPATH}/bam_allele_counts_to_vcf.sh -a ${DNABAM} -b ${RNABAM} -v ${VCF} -r ${REF} > ${TRACK}.alleleCountOut 2> ${TRACK}.alCount.perfOut
if [ $? -eq 0 ] ; then
    mv ${VCF}.allele_counts.vcf ${OUT}
    mv ${TRACK}.alleleCountOut ${TRACK}.alleleCountPass
else
    mv ${TRACK}.alleleCountOut ${TRACK}.alleleCountFail
fi
rm -f ${TRACK}.alleleCountInQueue
endTime=`date +%s`
elapsed=$(( $endTime - $beginTime ))
(( hours=$elapsed/3600 ))
(( mins=$elapsed%3600/60 ))
echo "RUNTIME:ALLELECOUNT:$hours:$mins" > ${TRACK}.alleleCount.totalTime
echo "### Ending allele count "
