#!/bin/bash
#####################################################################
# Copyright (c) 2011 by The Translational Genomics Research
# Institute. All rights reserved. This License is limited to, and you may
# use the Software solely for, your own internal and non-commercial use
# for academic and research purposes. Without limiting the foregoing, you
# may not use the Software as part of, or in any way in connection with
# the production, marketing, sale or support of any commercial product or
# service or for any governmental purposes. For commercial or governmental
# use, please contact dcraig@tgen.org. By installing this Software you are
# agreeing to the terms of the LICENSE file distributed with this
# software.
#####################################################################

thisStep="medusa_nextJob_vcfMerger.txt"
nxtStep1="medusa_nextJob_mergeVcfAlleleCount.txt"
pbsHome="/home/tgenjetstream/medusa-pipe/jobScripts"
constants="/home/tgenjetstream/central-pipe/constants/constants.txt"
constantsDir="/home/tgenjetstream/central-pipe/constants"
myName=`basename $0 | cut -d_ -f2`

time=`date +%d-%m-%Y-%H-%M`
echo "Starting $0 at $time"
if [ "$1" == "" ] ; then
	echo "### Please provide runfolder as the only parameter"
	echo "### Exiting!!!"
	exit
fi
runDir=$1
projName=`basename $runDir | awk -F'_ps20' '{print $1}'`
configFile=$runDir/$projName.config
if [ ! -e $configFile ] ; then
	echo "### Config file not found at $configFile!!!"
	echo "### Exiting!!!"
	exit
else
	echo "### Config file found."
fi
recipe=`cat $configFile | grep "^RECIPE=" | cut -d= -f2 | head -1 | tr -d [:space:]`
debit=`cat $configFile | grep "^DEBIT=" | cut -d= -f2 | head -1 | tr -d [:space:]`

nCores=`grep @@${myName}_CORES= $constantsDir/$recipe | cut -d= -f2`


snpSift=`grep @@"$recipe"@@ $constants | grep @@SNPEFFPATH= | cut -d= -f2`
samTools=`grep "@@"$recipe"@@" $constants | grep @@SAMTOOLSPATH= | cut -d= -f2`
varScan=`grep @@VARSCANPATH= $constantsDir/$recipe | cut -d= -f2`
ref=`grep "@@"$recipe"@@" $constants | grep @@REF= | cut -d= -f2`
refDict=${ref//fa/dict}
cosmicVcf=`grep "@@"$recipe"@@" $constants | grep @@COSMIC_VCF= | cut -d= -f2`
snps=`grep "@@"$recipe"@@" $constants | grep @@SNPS= | cut -d= -f2`
indels=`grep @@"$recipe"@@ $constants | grep @@INDELS= | cut -d= -f2`

rnaAligner=`grep "@@"$recipe"@@" $constants | grep @@RNAALIGNER= | cut -d= -f2`
gatkPath=`grep @@"$recipe"@@ $constants | grep @@GATKPATH= | cut -d= -f2`
hapmap=`grep @@"$recipe"@@ $constants | grep @@HAPMAP= | cut -d= -f2`
omni=`grep @@"$recipe"@@ $constants | grep @@OMNI= | cut -d= -f2`

snpeffdb=`grep @@"$recipe"@@ $constants | grep @@SNPEFFDB= | cut -d= -f2`
dbsnp=`grep @@"$recipe"@@ $constants | grep @@SNPS= | cut -d= -f2`
snpeffPath=`grep @@"$recipe"@@ $constants | grep @@SNPEFFPATH= | cut -d= -f2`

DBNSFP=/home/tgenref/pecan/bin/vcfMerger/dbNSFP2.4.txt.gz
VCFMERGER="/home/tgenref/pecan/bin/vcfMerger_V1/production.version.VCFMERGER_V1.NoNorm.20150720/pecan.merge.3vcfs.main.sh"
VCFMERGER_DIR="/home/tgenref/pecan/bin/vcfMerger_V1/production.version.VCFMERGER_V1.NoNorm.20150720"
VCFSORTER=/home/tgenref/pecan/bin/vcfMerger/vcfsorter.pl
RNA_VCF_HEADER=/home/tgenref/pecan/bin/vcfMerger/RNA_VCF_HEADER.vcf
POST_MERGE_VENN=/home/tgenref/pecan/bin/vcfMerger_V1/production.version.VCFMERGER_V1.NoNorm.20150720/pecan.Venn_postMMRF_specific_filtering.sh
#DBSNP=/home/tgenref/pecan/bin/vcfMerger/dbsnp_137.b37.vcf

if [[ "$recipe" == "choc01"  ]] ; then
	COSMIC=/home/tgenref/pecan/bin/vcfMerger/CosmicCodingMuts_v66_20130725_withCHR.sorted.vcf
else
	COSMIC=/home/tgenref/pecan/bin/vcfMerger/CosmicCodingMuts_v66_20130725_sorted.vcf
fi
if [[ "$recipe" == "choc01"  ]] ; then
	KG=/home/tgenref/pecan/bin/vcfMerger/1000G_phase1.snps.high_confidence.withCHR.b37.vcf
else
	KG=/home/tgenref/pecan/bin/vcfMerger/1000G_phase1.snps.high_confidence.b37.vcf
fi

if [[ "$recipe" == "choc01"  ]] ; then
	NHLBI=/home/tgenref/pecan/bin/vcfMerger/ESP6500SI-V2_snps_indels_withCHR.vcf

elif [[ "$recipe" == "TPRC" ]] ; then

	NHLBI=/home/tgenref/pecan/bin/vcfMerger/ESP6500SI-V2_snps_indels_TPRC.vcf
else 
	NHLBI=/home/tgenref/pecan/bin/vcfMerger/ESP6500SI-V2_snps_indels.vcf
fi

echo "### projName: $projName"
echo "### confFile: $configFile"
d=`echo $runDir | cut -c 2-`

skipLines=1
qsubFails=0
###first check all these vcfs are complete/passed
for dnaPairLine in `cat $configFile | grep '^DNAPAIR='`
do
	rnaBam=""
	echo "### DNA pair line is $dnaPairLine for seurat stuff"
	sampleNames=`echo $dnaPairLine | cut -d= -f2`
	alleleCount=`cat $configFile | grep '^TRIPLET4ALLELECOUNT=' | grep ${sampleNames} | head -1`
	if [ -z "$alleleCount" ] ; then
		echo "allele count not requested for this DNAPAIR"
	else
		rnaSample=`echo $alleleCount | cut -d, -f3`
		rnaBam=`find $runDir -name "${rnaSample}.proj.Aligned.out.sorted.md.bam" | head -1`
		echo "allele count is requested for $sampleNames"
		echo "the matching rnaSample is $rnaSample"
	fi

	for eachSample in ${sampleNames//,/ }
	do
		((sampleCount++))
		#echo "eachsample: $eachSample"
		sampleLine=`cat $configFile | awk '/^SAMPLE=/' | awk 'BEGIN{FS=","} $2=="'"$eachSample"'"'`
		kitName=`echo $sampleLine | cut -d= -f2 | cut -d, -f1`
		samName=`echo $sampleLine | cut -d= -f2 | cut -d, -f2`
		assayID=`echo $sampleLine | cut -d= -f2 | cut -d, -f3`
	done
	control=`echo $dnaPairLine | cut -d= -f2 | cut -d, -f1`
	tumor=`echo $dnaPairLine | cut -d, -f2`
	echo "control = $control tumor = $tumor"
	usableName=${sampleNames//,/-}
	sampleCount=0
	missingSampleCount=0
	sampleList=""
	echo "$kitName"	
	if [[ "$kitName" == "TSE61" ]] ; then
		bedFile="/home/tgenref/pipeline_v0.3/annotations/exome_capture/illumina_truseq/TruSeq_exome_targeted_regions_b37_padded.bed"
	elif [[ "$kitName" == *S5U ]] || [[ "$kitName" == *S5X ]] ; then
		bedFile="/home/tgenref/pipeline_v0.3/ensembl70/Ensembl_v70_hs37d5_exonic_coordinates_touched_v5UTR_padded25.bed"
	elif [[ "$kitName" == *STX ]] ; then
		#bedFile="/home/tgenref/pipeline_v0.4/annotations/exome_capture/strexome/Strexome_targets_sortedTabs2_padded150.bed"
		bedFile="/home/tgenref/pipeline_v0.4/annotations/exome_capture/strexome/Strexome_targets_intersect_sorted_padded100.bed"
	elif [[ "$kitName" == *SCR ]] ; then
                #bedFile="/home/tgenref/pecan/annotations/exome_capture/agilent_clinical_research_exome/Agilent_Clinical_Research_Exome_hs37d5_TargetsPadded25_sortedTabs2_Picard.txt"
		bedFile="/home/tgenref/pecan/annotations/exome_capture/agilent_clinical_research_exome/Agilent_Clinical_Research_Exome_hs37d5_PaddedTargets_intersect_sorted_padded100.bed"
	elif [[ "$kitName" == *S2X ]] ; then
		#bedFile="/home/tgenref/pipeline_v0.4/annotations/exome_capture/Agilent_V2_hs37d5/Agilent_V2_hs37d5_TargetsPadded25sorted_Picard.txt"
		bedFile="/home/tgenref/pipeline_v0.4/annotations/exome_capture/Agilent_V2_hs37d5/Agilent_V2_hs37d5_Targets_intersect_sorted_padded100.bed"
	elif [[ "$kitName" == *STL ]] ; then
		#bedFile="/home/tgenref/pecan/annotations/exome_capture/strexome_lite/temp/Strexome_Lite_Targets_padded25.bed"
		bedFile="/home/tgenref/pecan/annotations/exome_capture/strexome_lite/Strexome_Lite_Targets_intersect_sorted_padded100.bed"
	elif [[ "$kitName" == *S1X ]] ; then
                #bedFile="/home/tgenref/pecan/annotations/exome_capture/agilent_SureSelectV1/temp/SureSelectV1_hs37d5_TargetsPadded25_Picard.txt"
		bedFile="/home/tgenref/pecan/annotations/exome_capture/agilent_SureSelectV1/SureSelectV1_hs37d5_PaddedTargets_intersect_sorted_padded100.bed"
	elif [[ "$kitName" == *S6X ]] ; then
		#bedFile="/home/tgenref/pecan/annotations/exome_capture/agilent_v6_noUTR/Agilent_V6_noUTR_hs37d5_TargetsPadded25.txt"
		bedFile="/home/tgenref/pecan/annotations/exome_capture/agilent_v6_noUTR/Agilent_V6_noUTR_hs37d5_Targets_intersect_sorted_padded100.bed"
	elif [[ "$kitName" == *SXP ]] ; then
		#bedFile="/home/tgenref/pecan/annotations/exome_capture/prostateStrexome/prostateStrexome.targetsPadded25.txt"
		bedFile="/home/tgenref/pecan/annotations/exome_capture/Agilent_SureSelect_V6R2_plusUTR/Agilent_SureSelect_V6R2_plusUTR_hs37d5_GRCh37.74_PaddedTargets_intersect_sorted_padded100.bed"
	elif [[ "$kitName" == *S4X ]] ; then
                bedFile="/home/tgenref/pecan/annotations/exome_capture/agilent_v4_noUTR/Agilent_V4_noUTR_hs37d5_Targets_intersect_sorted_padded100.bed"
	elif [[ "$kitName" == *E62 ]] ; then
		bedFile="/home/tgenref/pecan/annotations/exome_capture/illumina_nextera_expanded/NexteraExpandedExome_hs37d5_Targets_PicardPadded100.bed"
	elif [[ "$kitName" == *SC2 ]] ; then
                bedFile="/home/tgenref/annotations/dog/canfam3/vcfMergerBed/agilent_canine_exonV2_targets.padded100.bed"
        elif [[ "$kitName" == *S6A ]] ; then
                bedFile="/home/tgenref/pecan/annotations/exome_capture/StrAD/StrAD_targets_intersect_sorted_padded100.bed"
        elif [[ "$kitName" == *S4U ]] ; then
                bedFile="/home/tgenref/pecan/annotations/exome_capture/Agilent_SureSelect_V4_plusUTR/Agilent_SureSelect_V4_plusUTR_hs37d5_GRCh37.74_PaddedTargets_intersect_sorted_padded100.bed"
	elif [[ "$kitName" == *ST2 ]] ; then
                bedFile="/home/tgenref/pecan/annotations/exome_capture/Agilent_SureSelect_V6R2_StrexomeV2/Agilent_SureSelect_V6R2_StrexomeV2_hs37d5_GRCh37.74_PaddedTargets_intersect_sorted_padded100.bed"
	elif [[ "$kitName" == *CCC ]] ; then
                bedFile="/home/tgenref/pecan/annotations/exome_capture/Agilent_ClearSeq_Beta_ComprehensiveCancer/Agilent_ClearSeq_Beta_ComprehensiveCancer_hs37d5_GRCh37.74_PaddedTargets_intersect_sorted_padded100.bed"
        fi
	#bedFileGrep=$kitName"_CNABED"
        #bedFile=`grep "@@"$recipe"@@" $constants | grep @@"$bedFileGrep"= | cut -d= -f2`
        echo "### BED FILE= $bedFile"
	
	echo "first checking for seurat snpeff vcf"
	seuratTrackName="$runDir/seurat/$usableName/$usableName"
	if [ ! -e $seuratTrackName.seurat.vcf.snpEffPass ] ; then
		echo "### Seurat snpEffPass doesnt exist yet: $seuratTrackName.seurat.vcf.snpEffPass"
		((qsubFails++))
		exit
	fi
	echo "checking for strelka snpeff vcfs"	
	strelkaTrackName="$runDir/strelka/$usableName"
	vcfPre="$runDir/strelka/$usableName/myAnalysis/results/$usableName"
	if [[ ! -e $vcfPre.strelka.all.somatic.snvs.vcf.snpEffPass || ! -e $vcfPre.strelka.passed.somatic.snvs.vcf.snpEffPass || ! -e $vcfPre.strelka.passed.somatic.indels.vcf.snpEffPass || ! -e $vcfPre.strelka.all.somatic.indels.vcf.snpEffPass ]] ; then 
		echo "### strelka snpEff doesn't exist for one of the 4 strelka vcfs"
		((qsubFails++))
                exit
	fi
	echo "now checking for mutect vcfs"
	mutectTrackName="$runDir/mutect/$usableName/$usableName"
	vcf="${mutectTrackName}_MuTect_All.vcf"
	if [ ! -e $vcf.snpEffPass  ] ; then
		echo "### mutect snpEff pass doesnt exist yet: $mutectTrackName.mutectPass"
		((qsubFails++))
		continue
	else

		mergerDir="$runDir/vcfMerger/$usableName"
		mkdir -p $mergerDir
		seuratVcf="$seuratTrackName.seurat.vcf"
		mutectVcf="${mutectTrackName}_MuTect_All.vcf"
		echo "mutect VCF: $mutectVcf"
		strelkaIndelVcf="$vcfPre.strelka.passed.somatic.indels.vcf"
		strelkaSnvVcf="$vcfPre.strelka.passed.somatic.snvs.vcf"
		seurat_basename=`basename ${seuratVcf} ".seurat.vcf"`
		
		if [[ -e ${mergerDir}/${seurat_basename}.vcfMergerPass || -e ${mergerDir}/${seurat_basename}.vcfMergerInQueue || -e ${mergerDir}/${seurat_basename}.vcfMergerFail ]] ; then
			echo "### This vcf merger pair already passed, failed, or inQueue."
			continue
		fi
                echo "### Submitting vcfs to queue for vcf merger..."
                #echo "qsub -A $debit -l nodes=1:ppn=8 -v SNPEFFPATH=$snpeffPath,TUMOR=$tumor,CONTROL=$control,SNPSIFT=$snpSift,DBNSP=$DBNSP,SAMTOOLS=$samTools,VARSCAN=$varScan,REF=$ref,DICT=$refDict,COSMIC=$COSMIC,KG=$KG,NHLBI=$NHLBI,SNPS=$snps,INDELS=$indels,GATK=$gatkPath,VCFMERGER=$VCFMERGER,VCFMERGER_DIR=$VCFMERGER_DIR,VCFSORTER=$VCFSORTER,RNA_VCF_HEADER=$RNA_VCF_HEADER,POST_MERGE_VENN=$POST_MERGE_VENN,DBSNP=$dbsnp,DBVERSION=$snpeffdb,SEURAT_VCF=$seuratVcf,MUTECT_VCF=$mutectVcf,STRELKA_SNV_VCF=$strelkaSnvVcf,STRELKA_INDEL_VCF=$strelkaIndelVcf,MERGERDIR=$mergerDir,RNABAM=$rnaBam,ASSAYID=$assayID,BEDFILE=$bedFile,RUNDIR=$runDir,NXT1=$nxtStep1,D=$d $pbsHome/medusa_vcfMerger.pbs"

                #This qsub runs standard vcf merger and should be the one uncommented for general use
		qsub -A $debit -l nodes=1:ppn=8 -v SNPEFFPATH=$snpeffPath,CONTROL=$control,TUMOR=$tumor,SNPSIFT=$snpSift,DBNSFP=$DBNSFP,DBNSP=$DBNSP,SAMTOOLS=$samTools,VARSCAN=$varScan,REF=$ref,DICT=$refDict,COSMIC=$COSMIC,KG=$KG,NHLBI=$NHLBI,SNPS=$snps,INDELS=$indels,GATK=$gatkPath,VCFMERGER=$VCFMERGER,VCFMERGER_DIR=$VCFMERGER_DIR,VCFSORTER=$VCFSORTER,RNA_VCF_HEADER=$RNA_VCF_HEADER,POST_MERGE_VENN=$POST_MERGE_VENN,DBSNP=$dbsnp,DBVERSION=$snpeffdb,SEURAT_VCF=$seuratVcf,MUTECT_VCF=$mutectVcf,STRELKA_SNV_VCF=$strelkaSnvVcf,STRELKA_INDEL_VCF=$strelkaIndelVcf,MERGERDIR=$mergerDir,RNABAM=$rnaBam,ASSAYID=$assayID,BEDFILE=$bedFile,RUNDIR=$runDir,NXT1=$nxtStep1,D=$d $pbsHome/medusa_vcfMerger.pbs 
                
		#This qsub runs vcf merger starting from rm info keys if the merger is complete but there were issues further in the merger script
		#qsub -A $debit -l nodes=1:ppn=8 -v SNPEFFPATH=$snpeffPath,CONTROL=$control,TUMOR=$tumor,SNPSIFT=$snpSift,DBNSFP=$DBNSFP,DBNSP=$DBNSP,SAMTOOLS=$samTools,VARSCAN=$varScan,REF=$ref,DICT=$refDict,COSMIC=$COSMIC,KG=$KG,NHLBI=$NHLBI,SNPS=$snps,INDELS=$indels,GATK=$gatkPath,VCFMERGER=$VCFMERGER,VCFMERGER_DIR=$VCFMERGER_DIR,VCFSORTER=$VCFSORTER,RNA_VCF_HEADER=$RNA_VCF_HEADER,POST_MERGE_VENN=$POST_MERGE_VENN,DBSNP=$dbsnp,DBVERSION=$snpeffdb,SEURAT_VCF=$seuratVcf,MUTECT_VCF=$mutectVcf,STRELKA_SNV_VCF=$strelkaSnvVcf,STRELKA_INDEL_VCF=$strelkaIndelVcf,MERGERDIR=$mergerDir,RNABAM=$rnaBam,ASSAYID=$assayID,BEDFILE=$bedFile,RUNDIR=$runDir,NXT1=$nxtStep1,D=$d $pbsHome/medusa_vcfMergerFromInfoKeys.pbs 
		
		#This qsub runs vcf merger starting from annotation if the merger is complete but there were annotation issues that need debugging
		#qsub -A $debit -l nodes=1:ppn=8 -v SNPEFFPATH=$snpeffPath,CONTROL=$control,TUMOR=$tumor,SNPSIFT=$snpSift,DBNSFP=$DBNSFP,DBNSP=$DBNSP,SAMTOOLS=$samTools,VARSCAN=$varScan,REF=$ref,DICT=$refDict,COSMIC=$COSMIC,KG=$KG,NHLBI=$NHLBI,SNPS=$snps,INDELS=$indels,GATK=$gatkPath,VCFMERGER=$VCFMERGER,VCFMERGER_DIR=$VCFMERGER_DIR,VCFSORTER=$VCFSORTER,RNA_VCF_HEADER=$RNA_VCF_HEADER,POST_MERGE_VENN=$POST_MERGE_VENN,DBSNP=$dbsnp,DBVERSION=$snpeffdb,SEURAT_VCF=$seuratVcf,MUTECT_VCF=$mutectVcf,STRELKA_SNV_VCF=$strelkaSnvVcf,STRELKA_INDEL_VCF=$strelkaIndelVcf,MERGERDIR=$mergerDir,RNABAM=$rnaBam,ASSAYID=$assayID,BEDFILE=$bedFile,RUNDIR=$runDir,NXT1=$nxtStep1,D=$d $pbsHome/medusa_vcfMergerFromAnnotate.pbs
                if [ $? -eq 0 ] ; then
                        touch ${mergerDir}/${seurat_basename}.vcfMergerInQueue
                else
                        ((qsubFails++))
                fi
                sleep 2
        fi
done
if [ $qsubFails -eq 0 ] ; then
#all jobs submitted succesffully, remove this dir from messages
	echo "### I should remove $thisStep from $runDir."
	rm -f $runDir/$thisStep
else
#qsub failed at some point, this runDir must stay in messages
	echo "### Failure in qsub. Not touching $thisStep"
fi

time=`date +%d-%m-%Y-%H-%M`
echo "Ending $0 at $time"
