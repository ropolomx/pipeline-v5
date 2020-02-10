#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

label: "identify amplicon data type and suppress the the others"

requirements:
    ResourceRequirement:
        coresMax: 1
        ramMin: 8000 #check profiles and lower

inputs:
    seq_dir:
      type: Directory
      default: "sequence-categorisation"
      inputBinding:
        prefix: --seq-dir
    tax_dir:
      type: Directory
      default: "taxonomy-summary"
      inputBinding:
        prefix: --tax-dir

baseCommand: [its-length.py]
stdout: its_length

outputs:
    stdout: stdout

hints:
  - class: DockerRequirement
    dockerPull: 'alpine:3.7'

$namespaces:
 s: http://schema.org/
 iana: https://www.iana.org/assignments/media-types/
$schemas:
 - https://schema.org/docs/schema_org_rdfa.html

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder: "EMBL - European Bioinformatics Institute"