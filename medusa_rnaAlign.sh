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

thisStep="medusa_nextJob_rnaAlign.txt"
nxtStep1="medusa_nextJob_cuffLink.txt"
nxtStep2="medusa_nextJob_cuffDiff.txt"
nxtStep3="medusa_nextJob_htSeq.txt"
nxtStep4="medusa_nextJob_picardRNAMetrics.txt"
nxtStep5="medusa_nextJob_deSeq.txt"
nxtStep6="medusa_nextJob_checkProjectComplete.txt"
nxtStep7="medusa_nextJob_samtoolsStats.txt"
nxtStep8="medusa_nextJob_rnaMarkDup.txt"
nxtStep9="medusa_nextJob_cuffQuant.txt"
nxtStep10="medusa_nextJob_deSeq2.txt"
pbsHome="/home/mrussell/medusa-pipe/jobScripts"
constants="/home/mrussell/central-pipe/constants/constants.txt"
constantsDir="/home/mrussell/central-pipe/constants"
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


ref=`grep "@@"$recipe"@@" $constants | grep @@REF= | cut -d= -f2`
starGTF=`grep "@@"$recipe"@@" $constants | grep @@STARGTF= | cut -d= -f2`
usegtf=`grep "@@"$recipe"@@" $constants | grep @@TOPHATGTF= | cut -d= -f2`
rnaAligner=`grep "@@"$recipe"@@" $constants | grep @@RNAALIGNER= | cut -d= -f2`
dnaAligner=`grep "@@"$recipe"@@" $constants | grep @@DNAALIGNER= | cut -d= -f2`
indexbase=`grep @@"$recipe"@@ $constants | grep @@BOWTIE2INDEX= | cut -d= -f2`
transIndex=`grep @@"$recipe"@@ $constants | grep @@TRANSINDEX= | cut -d= -f2`
tophat2Path=`grep @@"$recipe"@@ $constants | grep @@TOPHAT2PATH= | cut -d= -f2`
bowtie2Path=`grep @@"$recipe"@@ $constants | grep @@BOWTIE2PATH= | cut -d= -f2`
samtoolsPath=`grep "@@"$recipe"@@" $constants | grep @@SAMTOOLSPATH= | cut -d= -f2`
picardPath=`grep @@"$recipe"@@ $constants | grep @@PICARDPATH= | cut -d= -f2`
starPath=`grep @@"$recipe"@@ $constants | grep @@STARPATH= | cut -d= -f2`
bwaPath=`grep "@@"$recipe"@@" $constants | grep @@BWAPATH= | cut -d= -f2`
refPreTophat=`grep @@"$recipe"@@ $constants | grep @@REFPRETOPHAT= | cut -d= -f2`
faiFile="$ref.fai"
echo "### projName: $projName"
echo "### confFile: $configFile"
echo "### rnaAlign: $rnaAligner"
d=`echo $runDir | cut -c 2-`

skipLines=1
qsubFails=0
###
for sampleLine in `cat $configFile | grep ^SAMPLE=`
do
	echo "sample is $sampleLine"
	kitName=`echo $sampleLine | cut -d= -f2 | cut -d, -f1`
	samName=`echo $sampleLine | cut -d= -f2 | cut -d, -f2`
	assayID=`echo $sampleLine | cut -d= -f2 | cut -d, -f3`
	libraID=`echo $sampleLine | cut -d= -f2 | cut -d, -f4`
	rnaStrand=`grep "@@"$kitName"@@" $constants | cut -d= -f2`
	echo "### What I have: Kit: $kitName, sample: $samName, assay: $assayID, libraID: $libraID, rnaStrand: $rnaStrand"
	if [ "$assayID" != "RNA" ] ; then
		echo "### Assay ID is $assayID. Skipping."
		continue
	fi
	
	read1Name=$runDir/$kitName/$samName/$samName.proj.R1.fastq.gz
	read2Name=$runDir/$kitName/$samName/$samName.proj.R2.fastq.gz
	echo "read 1 name: $read1Name"
	echo "read 2 name: $read2Name"
	echo "### Aligner for recipe $recipe is $rnaAligner"
	case $rnaAligner in 
	tophat) echo "tophat case"
		rgTag="@RG\tID:$rgID\tSM:$samName\tPL:ILLUMINA\tLB:$lbID\tPI:$insertSize"
		thisPath=`dirname $runDir`
		cd $thisPath
		ownDir=${read1Name/.proj.R1.fastq.gz/.topHatDir}
		if [[ ! -e $read1Name || ! -e $read2Name || ! -e $read1Name.mergeFastqPass || ! -e $read2Name.mergeFastqPass ]] ; then
			echo "one of the fastq files or read pass files dont exist"
			echo "read1Pass: $read1Name.mergeFastqPass"
			echo "read2Pass: $read2Name.mergeFastqPass"
			((qsubFails++))
			continue
		fi
 		if [[ -e $ownDir.thPass || -e $ownDir.thFail || -e $ownDir.thInQueue ]] ; then 
			echo "tophat already done, failed or inQueue"
			continue
		fi 
		if [ ! -d $ownDir ] ; then
			mkdir -p $ownDir
		fi

		#creating linked files to the original reads
		r1Name=`basename $read1Name`
		r2Name=`basename $read2Name`
		cd $ownDir
		ln -s $read1Name $r1Name
		read1Name=$ownDir/$r1Name
		ln -s $read2Name $r2Name
		read2Name=$ownDir/$r2Name
		cd -
		#done creating links. vars for reads changed.
		echo "read 1 name: $read1Name"
		echo "read 2 name: $read2Name"
		echo "submitting $ownDir to queue for tophat align..."
		qsub -A $debit -l nodes=1:ppn=$nCores -v REFPRETOPHAT=$refPreTophat,DNAALIGNER=$dnaAligner,FAI=$faiFile,BOWTIE2PATH=$bowtie2Path,TOPHAT2PATH=$tophat2Path,PICARDPATH=$picardPath,SAMTOOLSPATH=$samtoolsPath,BWAPATH=$bwaPath,RGID=$rgID,SAMPLE=$samName,REF=$ref,FASTQ1=$read1Name,FASTQ2=$read2Name,DIR=$ownDir,INDEXBASE=$indexbase,USEGTF=$usegtf,TRANSINDEX=$transIndex,NXT1=$nxtStep1,NXT2=$nxtStep2,NXT3=$nxtStep3,NXT4=$nxtStep4,NXT6=$nxtStep6,NXT7=$nxtStep7,NXT8=$nxtStep8,NXT9=$nxtStep9,NXT10=$nxtStep10,RUNDIR=$runDir,D=$d $pbsHome/medusa_tophat.pbs
		if [ $? -eq 0 ] ; then
			touch $ownDir.thInQueue
		else
			((qsubFails++))
		fi
		sleep 2
		;;
	star) echo "star case"
		thisPath=`dirname $runDir`
		cd $thisPath
		ownDir=${read1Name/.proj.R1.fastq.gz/.starDir}
		if [[ ! -e $read1Name || ! -e $read2Name || ! -e $read1Name.mergeFastqPass || ! -e $read2Name.mergeFastqPass ]] ; then
			echo "### one of the fastq files or read pass files dont exist"
			echo "### read1Pass: $read1Name.mergeFastqPass"
			echo "### read2Pass: $read2Name.mergeFastqPass"
			((qsubFails++))
			continue
		fi
 		if [[ -e $ownDir.starPass || -e $ownDir.starFail || -e $ownDir.starInQueue ]] ; then 
			echo "### STAR already done, failed or inQueue"
			continue
		fi 
		if [ ! -d $ownDir ] ; then
			mkdir -p $ownDir
		fi

		#creating linked files to the original reads
		r1Name=`basename $read1Name`
		r2Name=`basename $read2Name`
		cd $ownDir
		ln -s $read1Name $r1Name
		read1Name=$ownDir/$r1Name
		ln -s $read2Name $r2Name
		read2Name=$ownDir/$r2Name
		cd -
		#done creating links. vars for reads changed.
		echo "### read 1 name: $read1Name"
		echo "### read 2 name: $read2Name"
		lineLength=`gunzip -c $read1Name | head -2 | tail -1 | wc -c` 
		let "readLength=$lineLength-1"
		echo "### Read length determined to be $readLength for $ownDir"
		refGrep="STARREF"$readLength
		starRef=`grep "@@"$recipe"@@" $constants | grep @@"$refGrep"= | cut -d= -f2`
		echo "### Star reference is $starRef"
		echo "### submitting $ownDir to queue for STAR aligner... "
		if [[ $rnaStrand == "FIRST" || $rnaStrand == "SECOND" ]] ; then
			echo "##running stranded STAR case"
			qsub -A $debit -l nodes=1:ppn=$nCores -v SAMTOOLSPATH=$samtoolsPath,STARPATH=$starPath,STARREF=$starRef,STARGTF=$starGTF,FASTQ1=$read1Name,FASTQ2=$read2Name,DIR=$ownDir,NXT1=$nxtStep1,NXT2=$nxtStep2,NXT3=$nxtStep3,NXT4=$nxtStep4,NXT5=$nxtStep5,NXT6=$nxtStep6,NXT7=$nxtStep7,NXT8=$nxtStep8,NXT9=$nxtStep9,NXT10=$nxtStep10,RUNDIR=$runDir,RNASTRAND=$rnaStrand,D=$d $pbsHome/medusa_strandedStar.pbs
			if [ $? -eq 0 ] ; then
				touch $ownDir.starInQueue
			else
				((qsubFails++))
			fi
			sleep 2
		else
			echo "##running unstranded STAR case"
			qsub -A $debit -l nodes=1:ppn=$nCores -v SAMTOOLSPATH=$samtoolsPath,STARPATH=$starPath,STARREF=$starRef,STARGTF=$starGTF,FASTQ1=$read1Name,FASTQ2=$read2Name,DIR=$ownDir,NXT1=$nxtStep1,NXT2=$nxtStep2,NXT3=$nxtStep3,NXT4=$nxtStep4,NXT5=$nxtStep5,NXT6=$nxtStep6,NXT7=$nxtStep7,NXT8=$nxtStep8,NXT9=$nxtStep9,NXT10=$nxtStep10,RUNDIR=$runDir,RNASTRAND=$rnaStrand,D=$d $pbsHome/medusa_star.pbs
			if [ $? -eq 0 ] ; then
				touch $ownDir.starInQueue
			else
				((qsubFails++))
			fi
			sleep 2
		fi
		;;
	anotherRNAaligner) echo "example RNA aligner"
		;;
	*) echo "I should not be here"
		;;
	esac 
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
