#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow
label: "fp_filter workflow"
requirements:
    - class: SubworkflowFeatureRequirement
inputs:
    cram:
        type: File
        secondaryFiles: [.crai,^.crai]
    reference:
        type: string
    vcf:
        type: File
        secondaryFiles: [.tbi]
    variant_caller:
        string
    sample_name:
        string?
    min_var_freq:
        float?
outputs:
    unfiltered_vcf:
        type: File
        outputSource: fp_index/indexed_vcf
        secondaryFiles: [.tbi]
    filtered_vcf:
        type: File
        outputSource: hard_filter/filtered_vcf
        secondaryFiles: [.tbi]
steps:
    cram_to_bam:
        run: ../cram_to_bam/workflow.cwl
        in:
            cram: cram
            reference: reference
        out:
            [bam]
    normalize_variants:
        run: ../definitions/tools/normalize_variants.cwl
        in:
            reference: reference
            vcf: vcf
        out:
            [normalized_vcf]
    fp_filter:
        run: ../definitions/tools/fp_filter.cwl
        in:
            reference: reference
            bam: cram_to_bam/bam
            vcf: normalize_variants/normalized_vcf
            sample_name: sample_name
            min_var_freq: min_var_freq
            output_vcf_basename:
                source: variant_caller
                valueFrom: $(self)_full
        out:
            [filtered_vcf]
    fp_bgzip:
        run: ../definitions/tools/bgzip.cwl
        in:
            file: fp_filter/filtered_vcf
        out:
            [bgzipped_file]
    fp_index:
        run: ../definitions/tools/index_vcf.cwl
        in:
            vcf: fp_bgzip/bgzipped_file
        out:
            [indexed_vcf]
    hard_filter:
        run: ../definitions/tools/select_variants.cwl
        in:
            reference: reference
            vcf: fp_index/indexed_vcf
            exclude_filtered: 
                default: true
            output_vcf_basename:
                source: variant_caller
                valueFrom: $(self)_filtered
        out:
            [filtered_vcf]

