#!/usr/bin/env cwl-runner
class: Workflow
cwlVersion: v1.0

requirements:
  SubworkflowFeatureRequirement: {}
  MultipleInputFeatureRequirement: {}
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}
  ScatterFeatureRequirement: {}
#  SchemaDefRequirement:
#    types:
#      - $import: ../tools/biom-convert/biom-convert-table.yaml

inputs:
    forward_reads: File
    reverse_reads: File
    qc_min_length: int

outputs:

  qc-statistics:
    type: Directory
    outputSource: single/qc-statistics
  qc_summary:
    type: File
    outputSource: single/qc_summary
  qc-status:
    type: File
    outputSource: single/qc-status
  motus_input:
    type: File
    outputSource: single/motus_input
  filtered_fasta:
    type: File
    outputSource: single/filtered_fasta

 # hashsum file
  hashsum_forward:
    type: File
    outputSource: hashsum_forward/hashsum
  hashsum_reverse:
    type: File
    outputSource: hashsum_reverse/hashsum

steps:

# << calculate hashsum >>
  hashsum_forward:
    run: ../../../utils/generate_checksum/generate_checksum.cwl
    in:
      input_file: forward_reads
    out: [ hashsum ]
  hashsum_reverse:
    run: ../../../utils/generate_checksum/generate_checksum.cwl
    in:
      input_file: reverse_reads
    out: [ hashsum ]

# << SeqPrep >>
  overlap_reads:
    label: Paired-end overlapping reads are merged
    run: ../../../tools/SeqPrep/seqprep.cwl
    in:
      forward_reads: forward_reads
      reverse_reads: reverse_reads
    out: [ merged_reads, forward_unmerged_reads, reverse_unmerged_reads ]

# << run single pipeline before-QC >>
  single:
    label: run single pipeline on merged reads
    run: raw-reads-single-1.cwl
    in:
      single_reads: overlap_reads/merged_reads
      qc_min_length: qc_min_length
    out:
      - qc-statistics
      - qc_summary
      - qc-status
      - filtered_fasta
      - motus_input
