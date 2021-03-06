#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool
$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/

label: "antiSMASH"

requirements:
  InlineJavascriptRequirement: {}
  ResourceRequirement:
    coresMax: 1
    ramMin: 200  # just a default, could be lowered


hints:
  DockerRequirement:
    dockerPull: 'alpine:3.7'

inputs:
  outputname:
    type: string
    inputBinding:
      prefix: -o

  input_js:
    type: File
    format: edam:format_3475  # TXT
    inputBinding:
      prefix: -i

baseCommand: [antismash_json_generation]

outputs:
  output_json:
    type: File
    format: edam:format_3475  # TXT
    outputBinding:
      glob: $(inputs.outputname)

$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/docs/schema_org_rdfa.html

's:author': 'Ekaterina Sakharova'
's:copyrightHolder': EMBL - European Bioinformatics Institute
's:license': "https://www.apache.org/licenses/LICENSE-2.0"

