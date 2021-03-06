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
    single_reads: File
    qc_min_length: int
    stats_file_name: string

outputs:

  qc-statistics:
    type: Directory
    outputSource: qc_stats/output_dir
  qc_summary:
    type: File
    outputSource: run_quality_control_filtering/stats_summary_file

  qc-status:
    type: File
    outputSource: QC-FLAG/qc-flag

  filtered_fasta:
    type: File
    outputSource: run_quality_control_filtering/filtered_file

  hashsum_input:
    type: File
    outputSource: hashsum/hashsum

steps:
# << calculate hashsum >>
  hashsum:
    run: ../../../utils/generate_checksum/generate_checksum.cwl
    in:
      input_file: single_reads
    out: [ hashsum ]

# << unzipping only >>
  unzip_reads:
    run: ../../../utils/multiple-gunzip.cwl
    in:
      target_reads: single_reads
      reads: { default: true }
    out: [ unzipped_merged_reads ]

  count_submitted_reads:
    run: ../../../utils/count_fastq.cwl
    in:
      sequences: unzip_reads/unzipped_merged_reads
    out: [ count ]

# << Trim and Reformat >>
  trimming:
    run: ../../subworkflows/trim_and_reformat_reads.cwl
    in:
      reads: unzip_reads/unzipped_merged_reads
    out: [ trimmed_and_reformatted_reads ]

# << QC filtering >>
  run_quality_control_filtering:
    run: ../../../tools/qc-filtering/qc-filtering.cwl
    in:
      seq_file: trimming/trimmed_and_reformatted_reads
      submitted_seq_count: count_submitted_reads/count
      stats_file_name: {default: 'qc_summary'}
      min_length: qc_min_length
      input_file_format: { default: 'fasta' }
    out: [ filtered_file, stats_summary_file ]

  count_processed_reads:
    run: ../../../utils/count_fasta.cwl
    in:
      sequences: run_quality_control_filtering/filtered_file
    out: [ count ]

# << QC FLAG >>
  QC-FLAG:
    run: ../../../utils/qc-flag.cwl
    in:
        qc_count: count_processed_reads/count
    out: [ qc-flag ]

# << QC >>
  qc_stats:
    run: ../../../tools/qc-stats/qc-stats.cwl
    in:
        QCed_reads: run_quality_control_filtering/filtered_file
        sequence_count: count_processed_reads/count
    out: [ output_dir, summary_out ]
