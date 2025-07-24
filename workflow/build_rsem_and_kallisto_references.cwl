cwlVersion: v1.2
class: Workflow
id: rmats_wf
label: "build_rsem_and_kallisto_references"
doc: |
  Build references for rsem and kallisto
requirements:
- class: ScatterFeatureRequirement
- class: StepInputExpressionRequirement
- class: InlineJavascriptRequirement
inputs:
  reference_fasta: { type: File, doc: "Reference fasta file", inputBinding: { position: 3} }
  reference_name: { type: string, doc: "Output file prefix. Recommend format: RSEM_<SOURCE><Version>/"}
  reference_gtf: { type: 'File?', doc: "gene model definitions. This OR gff required"}
  reference_gff: { type: 'File?', doc: "gene model definitions. This OR gtf required"}
  transcript_idx: { type: File, doc: "Kallisto index file name" }
  
outputs:
  rsem_reference_file: {type: 'File', outputSource: rsem_prepare_reference/rsem_reference}
  kallisto_index_output: {type: 'File', outputSource: kallisto_index/index_out}
  

steps:
  rsem_prepare_reference:
    run: ../tools/rsem_prepare_reference.cwl
    in:
      reference_fasta: reference_fasta
      reference_name: reference_name
      reference_gff: reference_gff
      reference_gtf: reference_gtf
    out: [rsem_reference, rsem_fasta]
  kallisto_index:
    run: ../tools/kallisto_index.cwl
    in:
      transcript_idx: transcript_idx
      transcript_fasta: rsem_prepare_reference/rsem_fasta
    out: [index_out]
