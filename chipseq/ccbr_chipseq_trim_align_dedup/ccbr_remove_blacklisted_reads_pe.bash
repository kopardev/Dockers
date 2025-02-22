#!/bin/bash
set -e -x -o pipefail
ncpus=`nproc`
ARGPARSE_DESCRIPTION="Remove reads aligning to blacklisted regions (including chrM and chr_rRNA)"      # this is optional
source /opt/argparse.bash || exit 1
argparse "$@" <<EOF || exit 1
parser.add_argument('--infastq1',required=True, help='input R1 fastq.gz file')
parser.add_argument('--infastq2',required=True, help='input R2 fastq.gz file')
parser.add_argument('--samplename',required=True, help='samplename')
parser.add_argument('--outfastq1',required=True, help='output R1 fastq.gz file')
parser.add_argument('--outfastq2',required=True, help='output R2 fastq.gz file')
EOF

infastq1=$INFASTQ1
infastq2=$INFASTQ2
samplename=$SAMPLENAME
outfastq1=$OUTFASTQ1
outfastq2=$OUTFASTQ2

outfastq1_nogz=`echo $outfastq1|sed "s/.gz//g"`
outfastq2_nogz=`echo $outfastq2|sed "s/.gz//g"`



bwa mem -t $ncpus /opt/the_blacklists.fa $infastq1 $infastq2 > ${samplename}.notAlignedToBlacklist.sam

samtools view -@ $ncpus -f12 -bS -o ${samplename}.notAlignedToBlacklist.bam ${samplename}.notAlignedToBlacklist.sam

samtools sort -@ $ncpus -n -T ${samplename}.notAlignedToBlacklist.tmp -o ${samplename}.notAlignedToBlacklist.qsorted.bam ${samplename}.notAlignedToBlacklist.bam

bedtools bamtofastq -i ${samplename}.notAlignedToBlacklist.qsorted.bam \
                      -fq ${outfastq1_nogz} \
                      -fq2 ${outfastq2_nogz}

nreads=`cat ${outfastq1_nogz}|wc -l`
echo "$nreads"|awk '{printf("%d\tAfter removing mito-ribo reads\n",$1/2)}' >> ${samplename}.nreads.txt

pigz -f -p $ncpus ${outfastq1_nogz}
pigz -f -p $ncpus ${outfastq2_nogz}

rm -f ${samplename}.notAlignedToBlacklist.sam \
${samplename}.notAlignedToBlacklist.bam \
${samplename}.notAlignedToBlacklist.qsorted.bam

