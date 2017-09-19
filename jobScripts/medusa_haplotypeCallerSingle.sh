#!/usr/bin/env bash
#SBATCH --job-name="medusa_hcSin"
#SBATCH --time=0-48:00:00
#SBATCH --mail-user=jetstream@tgen.org
#SBATCH --mail-type=FAIL


time=`date +%d-%m-%Y-%H-%M`
beginTime=`date +%s`
machine=`hostname`
echo "### NODE: $machine"
echo "### REF: ${REF}"
echo "### CHRLIST: ${CHRLIST}"
echo "### STEP: ${STEP}"
echo "### RUNDIR: ${RUNDIR}"
echo "### NXT1: ${NXT1}"
echo "### GATKPATH: ${GATKPATH}"
echo "### KNOWN: ${KNOWN}"
echo "### BAMLIST: ${BAMLIST}"

echo "### Haplotype caller started for multiple bams at $time."
perf stat java -Djava.io.tmpdir=${TMPDIR} -jar -Xmx32g ${GATKPATH}/GenomeAnalysisTK.jar \
-l INFO \
-R ${REF} \
-T HaplotypeCaller \
-L ${CHRLIST}/Step${STEP}.list \
-nct 8 \
-I ${BAMLIST} \
-D ${KNOWN} \
-mbq 10 \
-o ${TRK}_Step${STEP}.HC.vcf > ${TRK}_Step${STEP}.hcOut 2> ${TRK}_Step${STEP}.hapCal.perfOut
if [ $? -eq 0 ] ; then
    echo "${STEP} Completed" >> ${TRK}_hcStatus.txt
    PROGRESS=`wc -l ${TRK}_hcStatus.txt | awk '{print $1}'`
    mv ${TRK}_Step${STEP}.hcOut ${TRK}_Step${STEP}.hcPass
    touch ${RUNDIR}/${NXT1}
else
    mv ${TRK}_Step${STEP}.hcOut ${TRK}_Step${STEP}.hcFail
    rm -f ${TRK}_Step${STEP}.hcInQueue
    exit 1
fi
#IF the progress count equals the step count merge to single vcf
if [ ${PROGRESS} -eq 24 ]
then
    echo HapCaller_${STEP}.Done
    #Concatenate VCF with GATK
     java -cp ${GATKPATH}/GenomeAnalysisTK.jar org.broadinstitute.sting.tools.CatVariants \
        -R ${REF} \
        -V ${TRK}_Step1.HC.vcf \
        -V ${TRK}_Step2.HC.vcf \
        -V ${TRK}_Step3.HC.vcf \
        -V ${TRK}_Step4.HC.vcf \
        -V ${TRK}_Step5.HC.vcf \
        -V ${TRK}_Step6.HC.vcf \
        -V ${TRK}_Step7.HC.vcf \
        -V ${TRK}_Step8.HC.vcf \
        -V ${TRK}_Step9.HC.vcf \
        -V ${TRK}_Step10.HC.vcf \
        -V ${TRK}_Step11.HC.vcf \
        -V ${TRK}_Step12.HC.vcf \
        -V ${TRK}_Step13.HC.vcf \
        -V ${TRK}_Step14.HC.vcf \
        -V ${TRK}_Step15.HC.vcf \
        -V ${TRK}_Step16.HC.vcf \
        -V ${TRK}_Step17.HC.vcf \
        -V ${TRK}_Step18.HC.vcf \
        -V ${TRK}_Step19.HC.vcf \
        -V ${TRK}_Step20.HC.vcf \
        -V ${TRK}_Step21.HC.vcf \
        -V ${TRK}_Step22.HC.vcf \
        -V ${TRK}_Step23.HC.vcf \
        -V ${TRK}_Step24.HC.vcf \
        -out ${TRK}.HC.vcf \
        -assumeSorted
        if [ $? -eq 0 ] ; then
            touch ${TRK}.hcPass
        else
            touch ${TRK}.hcFail
        fi
        rm -f ${TRK}.hcInQueue
else
    echo
    echo HapCaller_${STEP}.Done
fi
rm -f ${TRK}_Step${STEP}.hcInQueue

endTime=`date +%s`
elapsed=$(( $endTime - $beginTime ))
(( hours=$elapsed/3600 ))
(( mins=$elapsed%3600/60 ))
echo "RUNTIME:GATKHC:$hours:$mins" > ${TRK}_Step${STEP}.hapCal.totalTime

time=`date +%d-%m-%Y-%H-%M`
echo "HC finished at $time."

