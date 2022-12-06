#!/bin/bash

singularity pull --name gatk.sif docker://broadinstitute/gatk:4.2.6.1

source config_gatk_cnv.txt

export SINGULARITY_BIND=${home}

BAMLINE=$(sed -n "$SLURM_ARRAY_TASK_ID"p $FILE)
BAMT=$(echo $BAMLINE | cut -d, -f1)
BAMC=$(echo $BAMLINE | cut -d, -f2)

tumor=${BAMDIR}/${BAMT}
normal=${BAMDIR}/${BAMC}

TID=$(basename $tumor | cut -d. -f1)
CID=$(basename $normal | cut -d. -f1)

# step1 read cram/bam files

singularity exec gatk.sif gatk CollectReadCounts \
        -I ${tumor} \
        -L ${intlist} \
        --interval-merging-rule OVERLAPPING_ONLY \
        -R ${refer} \
        -O ${output_path}/${TID}_t.counts.hdf5

singularity exec gatk.sif gatk CollectReadCounts \
        -I ${normal} \
        -L ${intlist} \
        --interval-merging-rule OVERLAPPING_ONLY \
        -R ${refer} \
        -O ${output_path}/${CID}_g.counts.hdf5

# step2 denoise

singularity exec gatk.sif gatk CreateReadCountPanelOfNormals \
        -I ${output_path}/${CID}_g.counts.hdf5 \
        --annotated-intervals ${inttsv} \
        -O ${output_path}/${CID}_cnv.pon.hdf5

singularity exec gatk.sif gatk DenoiseReadCounts \
        -I ${output_path}/${TID}_t.counts.hdf5 \
        --count-panel-of-normals ${output_path}/${CID}_cnv.pon.hdf5 \
        --annotated-intervals ${inttsv} \
        --standardized-copy-ratios ${output_path}/${TID}.standardizedCR.tsv \
        --denoised-copy-ratios ${output_path}/${TID}.denoisedCR.tsv

# step3 germline mutation

singularity exec gatk.sif gatk --java-options "-Xmx16g" CollectAllelicCounts \
        -L ${intlist} \
        -I ${tumor} \
        -R ${refer} \
        -O ${output_path}/${TID}_t.allelicCounts.tsv

singularity exec gatk.sif gatk --java-options "-Xmx16g" CollectAllelicCounts \
        -L ${intlist} \
        -I ${normal} \
        -R ${refer} \
        -O ${output_path}/${CID}_g.allelicCounts.tsv

# step4 modelsegments & plotting

singularity exec gatk.sif gatk --java-options "-Xmx${modelseg_mem}" ModelSegments \
        --denoised-copy-ratios ${output_path}/${TID}.denoisedCR.tsv \
        --allelic-counts ${output_path}/${TID}_t.allelicCounts.tsv \
        --normal-allelic-counts ${output_path}/${CID}_g.allelicCounts.tsv \
        --output ${output_path}/${TID} \
        --output-prefix ${TID}

# this step needs some r packages,optparse and data.table, using these commands to install:
# install.packages("optparse")
# install.packages("data.table")
# install.packages("ggplot2")

singularity exec gatk.sif gatk PlotModeledSegments \
        --denoised-copy-ratios ${output_path}/${TID}.denoisedCR.tsv \
        --allelic-counts ${output_path}/${TID}/${TID}.hets.tsv \
        --segments ${output_path}/${TID}/${TID}.modelFinal.seg \
        --sequence-dictionary ${dict} \
        --output-prefix ${TID} \
        -O ${output_path}/${TID}

# step5 clean up

rm ${output_path}/${TID}_t.counts.hdf5
rm ${output_path}/${CID}_g.counts.hdf5
rm ${output_path}/${CID}_cnv.pon.hdf5
# rm ${output_path}/${TID}.standardizedCR.tsv
# rm ${output_path}/${TID}.denoisedCR.tsv
rm ${output_path}/${TID}_t.allelicCounts.tsv
rm ${output_path}/${CID}_g.allelicCounts.tsv

# step6 cntools

# here I apply the rscrpt in the same directory
# the rscrpt have four arguments:
# 1. output path 2. geneinfo path 3. gatk output file "id.cr.igv.seg" 4. BAMID

# mkdir ${output_path}/${TID}/cntools_result

# gatk_outpath=${output_path}/${TID}/*.cr.igv.seg

# Rscript cntools_gatk.R ${output_path}/${TID}/cntools_result ${geneinfo_path} ${gatk_outpath} ${TID}
