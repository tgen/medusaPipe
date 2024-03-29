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

thisStep="medusa_nextJob_jointIR.txt"
nxtStepA="medusa_nextJob_mergeJointIRBams.txt"
nxtStep1="medusa_nextJob_haplotypeCaller.txt"
nxtStep2="medusa_nextJob_clonalCov.txt"
nxtStep3="medusa_nextJob_mutect.txt"
nxtStep4="medusa_nextJob_seurat.txt"
nxtStep5="medusa_nextJob_trn.txt"
nxtStep6="medusa_nextJob_strelka.txt"
nxtStep7="medusa_nextJob_snpSniff.txt"
nxtStep8="medusa_nextJob_REVseurat.txt"
pbsHome="/home/tgenjetstream/medusa-pipe/jobScripts"
constants="/home/tgenjetstream/central-pipe/constants/constants.txt"
constantsDir="/home/tgenjetstream/central-pipe/constants"
myName=`basename $0 | cut -d_ -f2`

declare -a chrGroups=(1:11:17:21 2:10:16:22 3:9:15:18:MT 4:7:14:Y 5:X:13:20 6:8:12:19)

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
rnaAligner=`grep "@@"$recipe"@@" $constants | grep @@RNAALIGNER= | cut -d= -f2`
gatkPath=`grep @@"$recipe"@@ $constants | grep @@GATKPATH= | cut -d= -f2`
indels=`grep @@"$recipe"@@ $constants | grep @@INDELS= | cut -d= -f2`

echo "### projName: $projName"
echo "### confFile: $configFile"
d=`echo $runDir | cut -c 2-`

skipLines=1
qsubFails=0
numJirSet=`cat $configFile | grep '^JIRSET=' | wc -l`
if [ $numJirSet -eq 0 ] ; then
	echo "There was no JIRSET line, will run with DNAPAIR/DNAFAMI"
	jirLine="^DNAPAIR=\|^DNAFAMI="
else
	echo "There was a JIRSET line, will run with JIRSET"
	jirLine="^JIRSET="
fi

###
for dnaPairLine in `cat $configFile | grep $jirLine`
#for dnaPairLine in `cat $configFile | grep '^DNAPAIR=\|^DNAFAMI='`
do
	echo "### DNA pair line is $dnaPairLine"
	sampleNames=`echo $dnaPairLine | cut -d= -f2 | cut -d\; -f1`
        shorterName=`echo $dnaPairLine | cut -d= -f2 | cut -d\; -f2`
        if [[ $shorterName == *,* ]] ; then
                shorterName=""
                echo "### No nick name detected for these pairs"
                usableName=${sampleNames//,/-}
        else
                echo "### Nick name for these pairs are: $shorterName"
                usableName="$shorterName"
        fi
	#sampleNames=`echo $dnaPairLine | cut -d= -f2 | cut -d ';' -f1`
	#nickName=`echo $dnaPairLine | cut -d ';' -f2`
	#if [[ $nickName == DNAPAIR*  ]] ; then
	#	echo "There isnt a nickname for this line, will use all sample names"
	#	usableName=${sampleNames//,/-}
	#	echo "usableName: $usableName"
	#else
	#	echo "The nickname for this JIRSET or DNAFAMI is $nickName"
	#	usableName="$nickName"
	#fi
	echo "sampleNames: $sampleNames"
	sampleCount=0
	missingSampleCount=0
	sampleList=""
	bigBamDetected=0
	for eachSample in ${sampleNames//,/ }
	do
		((sampleCount++))
		echo "eachsample: $eachSample"
		sampleLine=`cat $configFile | awk '/^SAMPLE=/' | awk 'BEGIN{FS=","} $2=="'"$eachSample"'"'`
		kitName=`echo $sampleLine | cut -d= -f2 | cut -d, -f1`
		samName=`echo $sampleLine | cut -d= -f2 | cut -d, -f2`
		eachSampleBam=$runDir/$kitName/$samName/$samName.proj.md.bam
		eachSamplePass=$runDir/$kitName/$samName/$samName.proj.bam.mdPass
		if [[ ! -e $eachSampleBam || ! -e $eachSamplePass ]] ; then
			echo "### Can't find the md bam or the md pass"
			echo "### BAM: $eachSampleBam"
			echo "### PAS: $eachSamplePass"
			((missingSampleCount++))
		else
			sampleList="-I $eachSampleBam $sampleList"		

			bamSize=`stat -c%s $eachSampleBam`
			if [ $bamSize -ge 36000000000 ] ; then
				echo "### This bam is greater than 36GB. Setting flag."
				bigBamDetected=1
			fi
		fi
	done
	if [ $missingSampleCount -eq 0 ] ; then
		echo "### All sample bams are found"
		sampleList="${sampleList%?}"
		echo "### Sample list: $sampleList"
	else
		echo "### There were missing things"
		echo "### Samples missing: $missingSampleCount/$sampleCount"
		((qsubFails++))
		continue
	fi
	jirDir="$runDir/jointIR"
	if [ ! -d $jirDir ] ; then
		mkdir $jirDir
	fi
	mkdir -p $jirDir/$usableName
	workDir="$jirDir/$usableName"
	irIntFile="$runDir/jointIR/$usableName/$usableName.intervals"
	trackName="$runDir/jointIR/$usableName/$usableName"
	#if [ $bigBamDetected -eq 0 ] ; then
	#	echo "### None of the bams must be bigger than 40GB."
		if [[ -e $trackName.jointIRInQueue || -e $trackName.jointIRPass || -e $trackName.jointIRFail ]] ; then 
			echo "### Joint indel realign is already done, failed or inQueue"
			continue
		fi 
		echo "### Submitting $usableName to queue for joint indel realignment..."
		qsub -A $debit -l nodes=1:ppn=$nCores -v WORKDIR=$workDir,GATKPATH=$gatkPath,TRK=$trackName,INTS=$irIntFile,INDELS=$indels,DIRNAME=$jirDir,BAMLIST="'$sampleList'",REF=$ref,NXT1=$nxtStep1,NXT2=$nxtStep2,NXT3=$nxtStep3,NXT4=$nxtStep4,NXT5=$nxtStep5,NXT6=$nxtStep6,NXT7=$nxtStep7,NXT8=$nxtStep8,RUNDIR=$runDir,D=$d $pbsHome/medusa_jointIR.pbs
		if [ $? -eq 0 ] ; then
		touch $trackName.jointIRInQueue
		else
			((qsubFails++))
		fi
	#else
	#	echo "### One of the bams must be bigger than 40GB."
        #        for chrGrp in "${chrGroups[@]}"
        #        do
	#		grpName=`echo $chrGrp | cut -d: -f1`
	#		if [[ -e $trackName.jointIR-group$grpName-InQueue || -e $trackName.jointIR-group$grpName-Pass || -e $trackName.jointIR-group$grpName-Fail ]] ; then 
	#			echo "### Joint indel realign on big bam group $chrGrp already done, failed, or inqueue."
	#			continue
	#		fi 
	#		bamName=`basename $trackName`
	#		echo "submitting chr grp $chrGrp on $trackName to queue for gatk unified genotyper"
	#		qsub -A $debit -l nodes=1:ppn=$nCores -v GRPNAME=$grpName,CHRGRP=$chrGrp,WORKDIR=$workDir,GATKPATH=$gatkPath,TRK=$trackName,INTS=$irIntFile,INDELS=$indels,DIRNAME=$jirDir,BAMLIST="'$sampleList'",REF=$ref,NXT1=$nxtStepA,RUNDIR=$runDir,D=$d $pbsHome/medusa_jointIRsplit.pbs
	#		if [ $? -eq 0 ] ; then
	#			touch $trackName.jointIR-group$grpName-InQueue
	#		else
	#			((qsubFails++))
	#		fi
	#		sleep 2
	#	done
	#fi
	#sleep 2
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
