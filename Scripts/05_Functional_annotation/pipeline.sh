
if [ $# -lt 2 ];then
        echo "Usage : sh $0 <GAGA_ID> <prefix>"
        exit
fi

genome=$1
prefix=$2

cat */*.gff > annotpipeline.gff3 # re-annotated gff

ln -s ../../../Original_annotations_to_replace/$genome\_final_annotation_repfilt.gff3 $genome.gff3 # original annotated gff

perl bin/extractID.pl annotpipeline.gff3 $prefix
perl bin/Step1_geneReplace.pl $genome.gff3 annotpipeline.gff3 $prefix.mRNA.lst $prefix.gene.lst $prefix > $genome.gff3.replace.gff3


perl bin/FindOverlapAtCDSlevel.pl OR.gff3 ./$genome.gff3.replace.gff3 > Overlap.lst
awk '($10>0)' Overlap.lst  > Overlap.lst.filter
perl bin/extractID2.pl Overlap.lst.filter $prefix > Overlap.lst.filter.id
perl bin/Step2_geneReplaceOR.pl $genome.gff3.replace.gff3 OR.gff3 Overlap.lst.filter.id > $genome.gff3.replace2.gff3
perl bin/FindOverlapAtCDSlevel.pl $genome.gff3.replace2.gff3 $genome.gff3.replace2.gff3 > Overlap.lst.replace
awk '($10>0)' Overlap.lst.replace > Overlap.lst.replace.filter1
awk '($1!=$2)' Overlap.lst.replace.filter1 > Overlap.lst.replace.filter2
perl bin/filter1.pl Overlap.lst.replace.filter2 $prefix > Overlap.lst.replace.filter3
perl bin/Step3_deleteOverlappingGenes.pl $genome.gff3.replace2.gff3 Overlap.lst.replace.filter3 $prefix > $genome.gff3.replace3.gff3
perl bin/addParent.pl $genome.gff3.replace3.gff3 > $genome.gff3.replace4.gff3
perl bin/addCDS.pl $genome.gff3.replace4.gff3 > $genome.gff3.replace5.gff3
perl bin/addTagCDSlength.pl $genome.gff3.replace5.gff3 $prefix > $genome.gff3.replace5.gff3.len 
perl bin/selectIsoform.pl $genome.gff3.replace5.gff3.len > $genome.gff3.replace5.gff3.len.representative
perl bin/filter2.pl $genome.gff3.replace5.gff3.len.representative $genome.gff3.replace5.gff3 > $genome.gff3.replace5.gff3.filter.gff3
perl bin/Step4_selectRepresentative.pl $genome.gff3.replace5.gff3.len.representative $genome.gff3.replace5.gff3.filter.gff3 > $genome.gff3.replace6.gff3
cp $genome.gff3.replace5.gff3.filter.gff3 $genome\_final_annotation_repfilt_addfunc.gff3
cp $genome.gff3.replace6.gff3 $genome\_final_annotation_repfilt_addfunc.representative.gff3
gzip $genome\_final_annotation_repfilt_addfunc.gff3
gzip $genome\_final_annotation_repfilt_addfunc.representative.gff3
