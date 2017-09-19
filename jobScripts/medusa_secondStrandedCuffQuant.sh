#$#### Author: Ahmet Kurdoglu #####
##### Parameterized PBS Script ####
#PBS -S /bin/bash
#SBATCH --job-name="medusa_SScuffQuant"
#SBATCH --time=0-48:00:00
#SBATCH --mail-user=jetstream@tgen.org
#SBATCH --mail-type=FAIL
#PBS -j oe
#SBATCH --output="/${D}/oeFiles/${PBS_JOBNAME}_${PBS_JOBID}.out"
#SBATCH --error="/${D}/oeFiles/${PBS_JOBNAME}_${PBS_JOBID}.err"
 
time=`date +%d-%m-%Y-%H-%M`
beginTime=`date +%s`
machine=`hostname`
echo "### NODE: $machine"
echo "### REF: ${REF}"
echo "### DIRNAME: ${DIRNAME}"
echo "### RUNDIR: ${RUNDIR}"
echo "### BAM: ${BAM}"
echo "### USEGTF: ${USEGTF}"
echo "### USEMASK: ${USEMASK}"
echo "### CQPATH: ${CUFFQUANTPATH}"
echo "### CLGTF: ${CUFFLINKGTF}"
echo "### CLMASK: ${CUFFLINKMASK}"
echo "### NXT1: ${NXT1}"
echo "### PARAMS: ${PARAMS}"

echo "TIME:$time starting cuff quant on ${DIRNAME}"
cd ${DIRNAME}

PARAMS=${PARAMS//\#/ }
echo "### params is $params"

perf stat ${CUFFQUANTPATH}/cuffquant ${PARAMS} --frag-bias-correct ${REF} --library-type fr-firststrand --mask-file ${CUFFLINKMASK} ${CUFFLINKGTF} ${BAM} 2> ${DIRNAME}.cuffQuant.perfOut > ${DIRNAME}.cuffQuantOut 2>&1
if [ $? -eq 0 ] ; then
    newName=`basename ${BAM}`
    newName=${newName/.proj.Aligned.out.sorted.md.bam}
    mv ${DIRNAME}.cuffQuantOut ${DIRNAME}.cuffQuantPass
    mv ${DIRNAME}/abundances.cxb ${DIRNAME}/$newName.cuffQuant.abundances.cxb
    #mv ${DIRNAME}/transcripts.gtf ${DIRNAME}/$newName.transcripts.gtf
    #mv ${DIRNAME}/skipped.gtf ${DIRNAME}/$newName.skipped.gtf
    #mv ${DIRNAME}/genes.fpkm_tracking ${DIRNAME}/$newName.genes.fpkm_tracking
    #mv ${DIRNAME}/isoforms.fpkm_tracking ${DIRNAME}/$newName.isoforms.fpkm_tracking
    #mv ${DIR}/transcripts.expr ${DIR}/${NEWNAME}_transcripts.expr
    #mv ${DIR}/genes.expr ${DIR}/${NEWNAME}_genes.expr
    #mv ${DIR}/isoforms.fpkm_tracking ${DIR}/${NEWNAME}_isoforms.fpkm_tracking
    #touch ${RUNDIR}/${NXT1}
else
    mv ${DIRNAME}.cuffQuantOut ${DIRNAME}.cuffQuantFail
fi
rm -f ${DIRNAME}.cuffQuantInQueue
endTime=`date +%s`
elapsed=$(( $endTime - $beginTime ))
(( hours=$elapsed/3600 ))
(( mins=$elapsed%3600/60 ))
echo "RUNTIME:CUFFLINKS:$hours:$mins" > ${DIRNAME}.cuffquant.totalTime

time=`date +%d-%m-%Y-%H-%M`
echo "TIME:$time finished cufflinks on ${DIRNAME}"
