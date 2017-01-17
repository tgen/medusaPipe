#!/bin/bash
#####################################################################
# Copyright (c) 2011 by The Translational Genomics Research
# Institute Ahmet Kurdoglu. All rights reserved. This License is limited 
# to, and you may use the Software solely for, your own internal and i
# non-commercial use for academic and research purposes. Without limiting 
# the foregoing, you may not use the Software as part of, or in any way 
# in connection with the production, marketing, sale or support of any 
# commercial product or service or for any governmental purposes. For 
# commercial or governmental use, please contact dcraig@tgen.org. By 
# installing this Software you are agreeing to the terms of the LICENSE 
# file distributed with this software.
#####################################################################
source ~/.bashrc
time=`date +%d-%m-%Y-%H-%M`
echo "Starting $0 at $time"
scriptsHome="/home/tgenjetstream/medusa-pipe"
logs="/scratch/tgenjetstream/medusaPipe/logs"
topProjDir="/scratch/tgenjetstream/centralPipe/projects"
myhostname=`hostname`

echo "### ~~Running on $myhostname~~"

findCount=`ps -e | awk '$4=="find"' | wc -l`
if [ $findCount -ge 3 ] ; then
    echo "Too many finds on $myhostname ($findCount) already, quitting for $myhostname!!!"
    exit
else
    echo "Find count is low on $myhostname ($findCount)."
fi

for messageFile in `find $topProjDir -maxdepth 2 -name [m-M]edusa_nextJob_*txt`
do
	projDir=`dirname $messageFile`
	msgName=`basename $messageFile`
	echo "### Message file: $msgName"
	case $msgName in
	Medusa_nextJob_copyFastqs.txt)	echo "### Will copy fastqs for $projDir"
		nohup $scriptsHome/medusa_copyFastqs.sh $projDir >> $projDir/logs/medusa_copyFastqsLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_runFastQC.txt)	echo "### Will run fastQC for $projDir"
		nohup $scriptsHome/medusa_runFastQC.sh $projDir >> $projDir/logs/medusa_runFastQCLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_splitFastqs.txt)	echo "### Will split fastqs for $projDir"
		nohup $scriptsHome/medusa_splitFastqs.sh $projDir >> $projDir/logs/medusa_splitFastqsLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_dnaAlign.txt)	echo "### Will run dnaAlign for $projDir"
		nohup $scriptsHome/medusa_dnaAlign.sh $projDir >> $projDir/logs/medusa_dnaAlignLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_digar.txt)	echo "### Will run digar for $projDir"
		nohup $scriptsHome/medusa_digar.sh $projDir >> $projDir/logs/medusa_digarLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_digarPost.txt)       echo "### Will run digarPost for $projDir"
                nohup $scriptsHome/medusa_digarPost.sh $projDir >> $projDir/logs/medusa_digarPostLOG.txt 2>&1 &
                sleep 1
                ;;
	medusa_nextJob_dnaAlignParts.txt)	echo "### Will run dnaAlign in parts for $projDir"
		nohup $scriptsHome/medusa_dnaAlignParts.sh $projDir >> $projDir/logs/medusa_dnaAlignPartsLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_indelRealign.txt)	echo "### Will run indel realign for $projDir"
		nohup $scriptsHome/medusa_indelRealign.sh $projDir >> $projDir/logs/medusa_indelRealignLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_indelRealignParts.txt)	echo "### Will run indel realign in parts for $projDir"
		nohup $scriptsHome/medusa_indelRealignParts.sh $projDir >> $projDir/logs/medusa_indelRealignPartsLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_recalibrate.txt)	echo "### Will run recalibrate for $projDir"
		nohup $scriptsHome/medusa_recalibrate.sh $projDir >> $projDir/logs/medusa_recalibrateLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_recalibrateParts.txt)	echo "### Will run recalibrate in parts for $projDir"
		nohup $scriptsHome/medusa_recalibrateParts.sh $projDir >> $projDir/logs/medusa_recalibratePartsLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_mergeBams.txt)	echo "### Will merge bams $projDir"
		nohup $scriptsHome/medusa_mergeBams.sh $projDir >> $projDir/logs/medusa_mergeBamsLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_mergeMiniBams.txt)	echo "### Will merge bams $projDir"
		nohup $scriptsHome/medusa_mergeMiniBams.sh $projDir >> $projDir/logs/medusa_mergeMiniBamsLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_markDups.txt)	echo "### Will run mark dups for $projDir"
		nohup $scriptsHome/medusa_markDups.sh $projDir >> $projDir/logs/medusa_markDupsLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_jointIR.txt)	echo "### Will run joint IR for $projDir"
		nohup $scriptsHome/medusa_jointIR.sh $projDir >> $projDir/logs/medusa_jointIRLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_mergeJointIRBams.txt)	echo "### Will run merging for joint IR bams for $projDir"
		nohup $scriptsHome/medusa_mergeJointIRBams.sh $projDir >> $projDir/logs/medusa_mergeJointIRBamsLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_seurat.txt)	echo "### Will run seurat $projDir"
		nohup $scriptsHome/medusa_seurat.sh $projDir >> $projDir/logs/medusa_seuratLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_REVseurat.txt)	echo "### Will run REVseurat $projDir"
		nohup $scriptsHome/medusa_REVseurat.sh $projDir >> $projDir/logs/medusa_REVseuratLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_strelka.txt)	echo "### Will run strelka $projDir"
		nohup $scriptsHome/medusa_strelka.sh $projDir >> $projDir/logs/medusa_strelkaLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_mutect.txt)	echo "### Will run mutect $projDir"
		nohup $scriptsHome/medusa_mutect.sh $projDir >> $projDir/logs/medusa_mutectLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_clonalCov.txt)	echo "### Will run clonal coverage for $projDir"
		nohup $scriptsHome/medusa_clonalCov.sh $projDir >> $projDir/logs/medusa_clonalCovLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_cna.txt)	echo "### Will run copy number analysis for $projDir"
		nohup $scriptsHome/medusa_cna.sh $projDir >> $projDir/logs/medusa_cnaLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_trn.txt)	echo "### Will run translocations analysis for $projDir"
		nohup $scriptsHome/medusa_trn.sh $projDir >> $projDir/logs/medusa_trnLOG.txt 2>&1 &
		sleep 1
		;;
	#medusa_nextJob_mergeSeuratVcfs.txt)	echo "### Will run merge seurat vcfs for $projDir"
	#	nohup $scriptsHome/medusa_mergeSeuratVcfs.sh $projDir >> $projDir/logs/medusa_mergeSeuratVcfsLOG.txt 2>&1 &
	#	sleep 1
	#	;;
	#medusa_nextJob_unifiedGenotyper.txt)	echo "### Will run unified genotyper for $projDir"
	#	nohup $scriptsHome/medusa_unifiedGenotyper.sh $projDir >> $projDir/logs/medusa_unifiedGenotyperLOG.txt 2>&1 &
	#	sleep 1
	#	;;
	medusa_nextJob_haplotypeCaller.txt)	echo "### Will run haplotype caller for $projDir"
		nohup $scriptsHome/medusa_haplotypeCaller.sh $projDir >> $projDir/logs/medusa_haplotypeCallerLOG.txt 2>&1 &
		sleep 1
		;;
	#medusa_nextJob_vqsr.txt)	echo "### Will run VQSR for $projDir"
	#	nohup $scriptsHome/medusa_vqsr.sh $projDir >> $projDir/logs/medusa_vqsrLOG.txt 2>&1 &
	#	sleep 1
	#	;;
	medusa_nextJob_snpEff.txt)	echo "### Will run snpEff for $projDir"
		nohup $scriptsHome/medusa_snpEff.sh $projDir >> $projDir/logs/medusa_snpEffLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_snpSniff.txt)	echo "### Will run snpSniff for $projDir"
		nohup $scriptsHome/medusa_snpSniffer.sh $projDir >> $projDir/logs/medusa_snpSnifferLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_checkProjectComplete.txt)	echo "### Will check if project complete for $projDir"
		nohup $scriptsHome/medusa_checkProjectComplete.sh $projDir >> $projDir/logs/medusa_checkProjectCompleteLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_summaryStats.txt)	echo "### Will run summary stats for $projDir"
		nohup $scriptsHome/medusa_summaryStats.sh $projDir >> $projDir/logs/medusa_summaryStatsLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_finalize.txt)	echo "### Will run finalize for $projDir"
		nohup $scriptsHome/medusa_finalize.sh $projDir >> $projDir/logs/medusa_finalizeLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_picardMultiMetrics.txt)	echo "### Will run picard Multi Metrics for $projDir"
		nohup $scriptsHome/medusa_picardMultiMetrics.sh $projDir >> $projDir/logs/medusa_picardMultiMetricsLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_picardGcBiasMetrics.txt)	echo "### Will run picard GcBias Metrics for $projDir"
		nohup $scriptsHome/medusa_picardGcBiasMetrics.sh $projDir >> $projDir/logs/medusa_picardGcBiasMetricsLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_picardHSMetrics.txt)	echo "### Will run picard HS Metrics for $projDir"
		nohup $scriptsHome/medusa_picardHSMetrics.sh $projDir >> $projDir/logs/medusa_picardHSMetricsLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_samtoolsStats.txt)	echo "### Will run samtools stats for $projDir"
		nohup $scriptsHome/medusa_samtoolsStats.sh $projDir >> $projDir/logs/medusa_samtoolsStatsLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_mergeFastqs.txt)	echo "### Will run mergeFastqs for $projDir"
		nohup $scriptsHome/medusa_mergeFastqs.sh $projDir >> $projDir/logs/medusa_mergeFastqsLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_detectFusion.txt)	echo "### Will run detect fusion for $projDir"
		nohup $scriptsHome/medusa_detectFusion.sh $projDir >> $projDir/logs/medusa_detectFusionLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_sailFish.txt)	echo "### Will run sail fish for $projDir"
		nohup $scriptsHome/medusa_sailFish.sh $projDir >> $projDir/logs/medusa_sailFishLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_tophatFusionPost.txt)	echo "### Will run tophat fusion post for $projDir"
		nohup $scriptsHome/medusa_tophatFusionPost.sh $projDir >> $projDir/logs/medusa_tophatFusionPostLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_rnaAlign.txt)	echo "### Will run rnaAlign for $projDir"
		nohup $scriptsHome/medusa_rnaAlign.sh $projDir >> $projDir/logs/medusa_rnaAlignLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_rnaMarkDup.txt)	echo "### Will run rna mark dups for $projDir"
		nohup $scriptsHome/medusa_rnaMarkDup.sh $projDir >> $projDir/logs/medusa_rnaMarkDupLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_picardRNAMetrics.txt)	echo "### Will run picardRNAMetrics for $projDir"
		nohup $scriptsHome/medusa_picardRNAMetrics.sh $projDir >> $projDir/logs/medusa_picardRNAMetricsLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_IGLbedCov.txt)	echo "### Will run IGL bed cov for $projDir"
		nohup $scriptsHome/medusa_IGLbedCov.sh $projDir >> $projDir/logs/medusa_IGLbedCovLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_cuffLink.txt)	echo "### Will run cuff links for $projDir"
		nohup $scriptsHome/medusa_cuffLink.sh $projDir >> $projDir/logs/medusa_cuffLinkLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_cuffQuant.txt)	echo "### Will run cuff quant for $projDir"
		nohup $scriptsHome/medusa_cuffQuant.sh $projDir >> $projDir/logs/medusa_cuffQuantLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_htSeq.txt)	echo "### Will run HT seq for $projDir"
		nohup $scriptsHome/medusa_htSeq.sh $projDir >> $projDir/logs/medusa_htSeqLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_cuffDiff.txt)	echo "### Will run cuff diff for $projDir"
		nohup $scriptsHome/medusa_cuffDiff.sh $projDir >> $projDir/logs/medusa_cuffDiffLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_deSeq.txt)	echo "### Will run deSeq for $projDir"
		nohup $scriptsHome/medusa_deSeq.sh $projDir >> $projDir/logs/medusa_deSeqLOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_deSeq2.txt)	echo "### Will run deSeq2 for $projDir"
		nohup $scriptsHome/medusa_deSeq2.sh $projDir >> $projDir/logs/medusa_deSeq2LOG.txt 2>&1 &
		sleep 1
		;;
	medusa_nextJob_vcfMerger.txt)    echo "### Will run vcf Merger for $projDir"
                nohup $scriptsHome/medusa_vcfMerger.sh $projDir >> $projDir/logs/medusa_vcfMergerLOG.txt 2>&1 &
                sleep 1
                ;;
        medusa_nextJob_mergeVcfAlleleCount.txt)       echo "### Will run merge vcf allele count for $projDir"
                nohup $scriptsHome/medusa_mergeVcfAlleleCount.sh $projDir >> $projDir/logs/medusa_vcfMergerACLOG.txt 2>&1 &
                sleep 1
                ;;
	medusa_nextJob_alleleCount.txt)	echo "### Will run alleleCount for $projDir"
		nohup $scriptsHome/medusa_alleleCount.sh $projDir >> $projDir/logs/medusa_alleleCountLOG.txt 2>&1 &
		sleep 1
		;;
	*) 	echo "### Nothing to process $msgName with on $myhostname. Skipped."
		sleep 1
		;;
	esac
done

echo "**********DONE************"
