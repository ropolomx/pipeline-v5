#!/usr/bin/env cwl-runner
class: Workflow
cwlVersion: v1.0

requirements:
  SubworkflowFeatureRequirement: {}
  MultipleInputFeatureRequirement: {}
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}
  ScatterFeatureRequirement: {}

inputs:
    forward_reads: File
    reverse_reads: File

    ssu_db: {type: File, secondaryFiles: [.mscluster] }
    lsu_db: {type: File, secondaryFiles: [.mscluster] }
    ssu_tax: File
    lsu_tax: File
    ssu_otus: File
    lsu_otus: File

    rfam_models: File[]
    rfam_model_clans: File

    ssu_label: string
    lsu_label: string
    5s_pattern: string

    unite_db: {type: File, secondaryFiles: [.mscluster] }
    unite_tax: File
    unite_otu_file: File
    unite_label: string
    itsonedb: {type: File, secondaryFiles: [.mscluster] }
    itsonedb_tax: File
    itsonedb_otu_file: File
    itsonedb_label: string

outputs:
  processed_nucleotide_reads:
    type: File
    outputSource: run_quality_control_filtering/filtered_file

  qc_stats_out:
    type: Directory
    outputSource: qc_stats/output_dir

  ncRNAs:
    type: File
    outputSource: classify/ncRNAs

  cmsearch_tblout:
    type: File
    outputSource: classify/cmsearch_tblout

  5s_fasta:
    type: File
    outputSource: classify/5S_fasta

  SSU_fasta:
    type: File
    outputSource: classify/SSU_fasta

  LSU_fasta:
    type: File
    outputSource: classify/LSU_fasta

  SSU_classifications:
    type: File
    outputSource: classify/SSU_classifications

  SSU_otu_tsv:
    type: File
    outputSource: classify/SSU_otu_tsv

  SSU_otu_txt:
    type: File
    outputSource: classify/SSU_otu_txt

  SSU_krona_image:
    type: File
    outputSource: classify/SSU_krona_image

  LSU_classifications:
    type: File
    outputSource: classify/LSU_classifications

  LSU_otu_tsv:
    type: File
    outputSource: classify/LSU_otu_tsv

  LSU_otu_txt:
    type: File
    outputSource: classify/LSU_otu_txt

  LSU_krona_image:
    type: File
    outputSource: classify/LSU_krona_image

steps:

# << SeqPrep >>
  overlap_reads:
    label: Paired-end overlapping reads are merged
    run: ../tools/SeqPrep/seqprep.cwl
    in:
      forward_reads: forward_reads
      reverse_reads: reverse_reads
    out: [ merged_reads, forward_unmerged_reads, reverse_unmerged_reads ]

  combine_overlapped_and_unmerged_reads:
    run: ../tools/SeqPrep/seqprep-merge.cwl
    in:
      merged_reads: overlap_reads/merged_reads
      forward_unmerged_reads: overlap_reads/forward_unmerged_reads
      reverse_unmerged_reads: overlap_reads/reverse_unmerged_reads
    out: [ merged_with_unmerged_reads ]

# << Trim and Reformat >>
  trim_quality_control:
    doc: |
      Low quality trimming (low quality ends and sequences with < quality scores
      less than 15 over a 4 nucleotide wide window are removed)
    run: ../tools/Trimmomatic/Trimmomatic-v0.36-SE.cwl
    in:
      reads1: combine_overlapped_and_unmerged_reads/merged_with_unmerged_reads
      phred: { default: '33' }
      leading: { default: 3 }
      trailing: { default: 3 }
      end_mode: { default: SE }
      minlen: { default: 100 }
      slidingwindow:
        default:
          windowSize: 4
          requiredQuality: 15
    out: [reads1_trimmed]

  convert_trimmed_reads_to_fasta:
    run: ../utils/fastq_to_fasta.cwl
    in:
      fastq: trim_quality_control/reads1_trimmed
    out: [ fasta ]

  clean_fasta_headers:
    run: ../utils/clean_fasta_headers.cwl
    in:
      sequences: convert_trimmed_reads_to_fasta/fasta
    out: [ sequences_with_cleaned_headers ]

  count_submitted_reads:
    run: ../utils/count_fastq.cwl
    in:
      sequences: combine_overlapped_and_unmerged_reads/merged_with_unmerged_reads
    out: [ count ]

  run_quality_control_filtering:
    run: ..tools/qc-filtering/qc-filtering.cwl
    in:
      seq_file: clean_fasta_headers/sequences_with_cleaned_headers
    out: [ filtered_file ]

  count_processed_reads:
    run: ../utils/count_fasta.cwl
    in:
      sequences: run_quality_control_filtering/filtered_file
    out: [ count ]

# << QC >>
  qc_stats:
    run: ../tools/qc-stats/qc-stats.cwl
    in:
        QCed_reads: run_quality_control_filtering/filtered_file
        sequence_count: count_processed_reads/count
    out: [ output_dir ]

# << Get RNA >>
  classify:
    run: rna_prediction-sub-wf.cwl
    in:
       input_sequences: run_quality_control_filtering/filtered_file
       silva_ssu_database: ssu_db
       silva_lsu_database: lsu_db
       silva_ssu_taxonomy: ssu_tax
       silva_lsu_taxonomy: lsu_tax
       silva_ssu_otus: ssu_otus
       silva_lsu_otus: lsu_otus
       ncRNA_ribosomal_models: rfam_models
       ncRNA_ribosomal_model_clans: rfam_model_clans
       pattern_SSU: ssu_label
       pattern_LSU: lsu_label
       pattern_5S: 5s_pattern
    out:
      - ncRNAs
      - cmsearch_tblout
      - 5S_fasta
      - SSU_fasta
      - LSU_fasta
      - SSU_coords
      - LSU_coords
      - SSU_classifications
      - SSU_otu_tsv
      - SSU_otu_txt
      - SSU_krona_image
      - LSU_classifications
      - LSU_otu_tsv
      - LSU_otu_txt
      - LSU_krona_image

# << ITS >>
