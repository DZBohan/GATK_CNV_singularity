#!/bin/bash

source config_gatk_cnv_prepare.txt

export SINGULARITY_BIND=${home}

# total two output files of these two pre-steps:
# targets.preprocessed.interval_list
# annotated_intervals.tsv
# they are required for the gatk cnv analysis steps.

# pre-step1 preprocess intervals

singularity exec gatk.sif gatk PreprocessIntervals \
        -L ${bed} \
        -R ${refer} \
        --bin-length 0 \
        --interval-merging-rule OVERLAPPING_ONLY \
        -O ${output_path}/targets.preprocessed.interval_list

# pre-step2 annotate intervals

singularity exec gatk.sif gatk AnnotateIntervals \
        -R ${refer} \
        -L ${output_path}/targets.preprocessed.interval_list \
        --interval-merging-rule OVERLAPPING_ONLY \
        -O ${output_path}/annotated_intervals.tsv
