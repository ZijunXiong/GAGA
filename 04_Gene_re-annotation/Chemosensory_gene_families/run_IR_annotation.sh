#!/bin/sh
#PBS -W group_list=ku_00039 -A ku_00039
#PBS -m n
#PBS -l nodes=1:ppn=4
#PBS -l mem=40gb
#PBS -l walltime=6:00:00

# Go to the directory from where the job was submitted (initial directory is $HOME)
echo Working directory is $PBS_O_WORKDIR
cd $PBS_O_WORKDIR

### Here follows the user commands:
# Define number of processors
NPROCS=`wc -l < $PBS_NODEFILE`
echo This job has allocated $NPROCS nodes

# Load all required modules for the job
#First load modules
module load ngs tools
module load anaconda3/4.4.0
module load jdk/19
module load perl
module load signalp/4.1g
#module load interproscan/5.51-85.0
module load interproscan/5.52-86.0
module load ncbi-blast/2.11.0+

# This is where the work is done
# Make sure that this script is not bigger than 64kb ~ 150 lines, otherwise put in seperat script and execute from here

GENOME="/home/projects/ku_00039/people/joeviz/GAGA_genomes/Genome_assemblies/GAGA_all_final_assemblies_softmasked/GAGA-0001_SLR-superscaffolder_final_dupsrm_filt.softMasked.fasta"
OUTDIR="GAGA-0001" # Directory must not exist before, or it will fail (unless it is used --overwrite)

mkdir $OUTDIR
cd $OUTDIR

## Getting annotations from BITACORA already run in the re-annotation pipeline
cp /home/projects/ku_00039/people/igngod/Gene-annotation-pipeline-main/Data/Genomes/$OUTDIR/gene_families_pipeline/IR_iGluR/Step2_bitacora/IR_iGluR/IR_iGluR_genomic_and_annotated_proteins_trimmed_idseqsclustered.gff3 Bitacora_raw.gff3


######## Generate a GFF3 and protein file

sed s/split/separated/g Bitacora_raw.gff3 > Bitacora_raws.gff3

perl /home/projects/ku_00039/people/joeviz/programs/bitacora/Scripts/Tools/gff2fasta_v3.pl $GENOME Bitacora_raws.gff3 Bitacora_raws
sed s/X*$// Bitacora_raws.pep.fasta > Bitacora_raws.pep.fasta.tmp
mv Bitacora_raws.pep.fasta.tmp Bitacora_raws.pep.fasta


# Identify and curate chimeric sequences

blastp -subject Bitacora_raws.pep.fasta -query /home/projects/ku_00039/people/joeviz/OR_annotation/Chemo_db/IR_iGluR_db_cf_hs_dmel.fasta -out Bitacora_raws.pep.fasta.iblast.txt -outfmt "6 std qlen slen" -evalue 1e-5

#perl /home/projects/ku_00039/people/joeviz/programs/bitacora_modftrimlength/Scripts/get_blastp_parsed_newv2.pl Bitacora_raws.pep.fasta.iblast.txt Bitacora_raws.pep.fasta.iblast 1e-5
#perl /home/projects/ku_00039/people/joeviz/programs/bitacora_modftrimlength/Scripts/get_blast_hmmer_combined.pl Bitacora_raws.pep.fasta.iblastblastp_parsed_list.txt Bitacora_raws.pep.fasta.iblast

perl /home/projects/ku_00039/people/joeviz/OR_annotation/get_blastp_parsed_newv2.pl Bitacora_raws.pep.fasta.iblast.txt Bitacora_raws.pep.fasta.iblast 1e-30
perl /home/projects/ku_00039/people/joeviz/OR_annotation/get_blast_hmmer_combined.pl Bitacora_raws.pep.fasta.iblastblastp_parsed_list.txt Bitacora_raws.pep.fasta.iblast

perl /home/projects/ku_00039/people/joeviz/OR_annotation/get_fullproteinlist_curatingchimeras.pl Bitacora_raws.pep.fasta Bitacora_raws.pep.fasta.iblast_combinedsearches_list.txt
perl /home/projects/ku_00039/people/joeviz/programs/bitacora_modftrimlength/Scripts/get_annot_genes_gff_v2.pl Bitacora_raws.gff3 $GENOME Bitacora_raws.pep.fasta.iblast_combinedsearches_full_fixed_list.txt Bitacora

sed s/separated/split/g Bitacora_annot_genes_trimmed.gff3 > Bitacora.gff3


perl /home/projects/ku_00039/people/joeviz/programs/bitacora/Scripts/Tools/gff2fasta_v3.pl $GENOME Bitacora.gff3 Bitacora
sed s/X*$// Bitacora.pep.fasta > Bitacora.pep.fasta.tmp
mv Bitacora.pep.fasta.tmp Bitacora.pep.fasta


######## Run Interpro in the protein set

f="Bitacora.pep.fasta"

interproscan.sh -i $f -t p -goterms -iprlookup -cpu 4   


######## Run blast with IR and iGluRs from Chemo_db to obtain names

blastp -query Bitacora.pep.fasta -db /home/projects/ku_00039/people/joeviz/OR_annotation/Chemo_db/IR_iGluR_db.fasta -outfmt "6 std qlen slen" -out Bitacora.pep.fasta.IRblast.txt -num_threads 4


######## Run script to rename the gff3 and generate the protein file and summary table

perl /home/projects/ku_00039/people/joeviz/OR_annotation/run_classification_bitacora_IR.pl Bitacora.gff3 $OUTDIR $GENOME


    
