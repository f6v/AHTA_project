#!/bin/bash/

set -e

fastq_file=$1

echo "Processing file $fastq_file"

sample_name=`basename $fastq_file .fastq`
sample_folder=`dirname $fastq_file`

genome_index=~/dev/bowtie/indexes/m_musculus_ncbi37

mkdir -p $sample_folder/results/fastqc
mkdir -p $sample_folder/results/bowtie/intermediate_bams
mkdir -p $sample_folder/results/trimmomatic

fastqc_out=$sample_folder/results/fastqc/

trimmed=$sample_folder/results/trimmomatic/${sample_name}_trimmed.fastq
align_out=$sample_folder/results/bowtie/${sample_name}_unsorted.sam
align_bam=$sample_folder/results/bowtie/${sample_name}_unsorted.bam
align_sorted=$sample_folder/results/bowtie/${sample_name}_sorted.bam
align_filtered=$sample_folder/results/bowtie/${sample_name}_aln_filt.bam

bowtie_results=$sample_folder/results/bowtie
intermediate_bams=$sample_folder/results/bowtie/intermediate_bams

echo "Running fastqc on raw file..."
fastqc $fastq_file -o $fastqc_out

echo "Running trimmomatic..."
java -jar ~/dev/trimmomatic-0.39/trimmomatic.jar SE -phred33 $fastq_file $trimmed ILLUMINACLIP:$sample_folder/adapters.fasta:2:30:10 SLIDINGWINDOW:4:15 MINLEN:36

echo "Running fastqc on trimmed file..."
fastqc $trimmed -o $fastqc_out

echo "Running bowtie..."
bowtie $genome_index -q $trimmed -p 4 -v 2 -m 1 -3 1 -S > $align_out

echo "Running samtools view..."
samtools view -h -S -b -@ 6 -o $align_bam $align_out

echo "Running sambamba sort..."
sambamba sort -t 6 -o $align_sorted $align_bam

echo "Running sambamba view..."
sambamba view -h -t 6 -f bam -F "[XS] == null and not unmapped " $align_sorted > $align_filtered

echo "Running samtools index..."
samtools index $align_filtered

echo "Cleaning up..."
mv $bowtie_results/${base}*sorted* $intermediate_bams

echo "Done."
