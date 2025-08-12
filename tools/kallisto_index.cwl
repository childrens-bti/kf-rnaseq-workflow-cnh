cwlVersion: v1.2
class: CommandLineTool
id: kallisto_index
requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'images.sbgenomics.com/uros_sipetic/kallisto:0.43.1'
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: 8
    ramMin: 10000
  - class: SchemaDefRequirement
    types:
    - $import: ../schema/reads_record_type.yml

baseCommand: []
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      kallisto index

inputs:
  transcript_idx: { type: string, inputBinding: { position: 2, prefix: '-i' }, doc: "Kallisto index file name" }
  transcript_fasta: { type: File, inputBinding: { position: 3 }, doc: "Input transcript fasta" }


outputs:
  index_out:
    type: File
    outputBinding:
      glob: "$(inputs.transcript_idx)"
