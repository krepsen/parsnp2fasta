#!/bin/bash
# turn your favorite parsnp file to fasta
# obviously require harvesttools - also require samtools, bcftools, perl5 (snippy - replace path with the location of your perl5), tabix, unt vcf-consensus

harvesttools -i parsnp.ggr -F ref.fa
samtools faidx ref.fa
contig=$(cat ref.fa.fai | sed 's/|/ /' | awk '{print $1}')
len=$(cat ref.fa.fai | sed 's/|/ /' | awk '{print $2}')

harvesttools -i parsnp.ggr -V parsnp.vcf
sed -i '1c\##fileformat=VCFv4.2' parsnp.vcf 
sed -i '2c\##commandLine="parsnp"' parsnp.vcf 
sed -i '3c\##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">' parsnp.vcf 
sed -i '4c\##INFO=<ID=TYPE,Number=A,Type=String,Description="Allele type: snp ins del">' parsnp.vcf 
sed -i "5c\##contig=<ID=${contig},len=${len}>" parsnp.vcf 

sed -i 's/NA/TYPE=snp/g' parsnp.vcf
sed -i 's/CID/PASS/g' parsnp.vcf
sed -i 's/ALN/PASS/g' parsnp.vcf
sed -i 's/LCB/PASS/g' parsnp.vcf
sed -i 's/PASS:PASS/PASS/g' parsnp.vcf


for file in parsnp.vcf; do
  for sample in `bcftools query -l $file`; do
    bcftools view -c1 -Oz -s $sample -o $sample.vcf.gz $file
  done
done

export PERL5LIB=/home/ngs/miniconda3/pkgs/snippy-3.1-0/perl5/

for FILE in *.vcf.gz;
do
	tabix $FILE
	cat ref.fa | vcf-consensus $FILE > ${FILE}.fa
done

for FILE in *.vcf.gz.fa;
do
	awk '/^>/ {gsub(/.vcf.gz.fa(sta)?$/,"",FILENAME);printf(">%s\n",FILENAME);next;} {print}' $FILE > ${FILE}.rename
done

endpath=$(basename $(pwd))
cat *.rename > ${endpath}.fasta

find . -name "*vcf.gz*" -type f -exec rm -rv {} \;
