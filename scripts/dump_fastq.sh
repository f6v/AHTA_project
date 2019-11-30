fastq_files=(SRR935858 SRR935859 SRR935860 SRR935861 SRR935862 SRR935863)
for i in "${fastq_files[@]}"
do
	fastq-dump $i
done
