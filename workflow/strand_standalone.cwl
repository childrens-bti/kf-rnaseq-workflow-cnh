cwlVersion: v1.2
class: Workflow
id: strand_standalone_wf
label: "Strand Standalone"
doc: |
  Workflow running cram to bam and strandedness tool
requirements:
- class: ScatterFeatureRequirement
- class: StepInputExpressionRequirement
- class: InlineJavascriptRequirement
inputs:
  input_aligned: {type: 'File', secondaryFiles: [{pattern: '.bai', required: false}, {pattern: '^.bai', required: false}, {pattern: '.crai', required: false},
    {pattern: '^.crai', required: false}], doc: "Input bam or cram file"}
  gtf_anno: {type: 'File', doc: "General transfer format (gtf) file with gene models corresponding to fasta reference", "sbg:suggestedValue": {
      class: File, path: 62853e7ad63f7c6d8d7ae5a4, name: gencode.v39.primary_assembly.annotation.gtf}}
  reference_fasta: {type: 'File?', doc: "GRCh38.primary_assembly.genome.fa", "sbg:suggestedValue": {class: File, path: 5f500135e4b0370371c051b4,
      name: GRCh38.primary_assembly.genome.fa, secondaryFiles: [{class: File, path: 62866da14d85bc2e02ba52db, name: GRCh38.primary_assembly.genome.fa.fai}]},
    secondaryFiles: ['.fai']}
  bam_strandness_nreads: {type: 'int?', doc: "strandedness nreads (null = tool default)"}
  kallisto_idx: {type: 'File', doc: "Specialized index of a **transcriptome** fasta file for kallisto", "sbg:suggestedValue": {class: File,
      path: 62853e7ad63f7c6d8d7ae5a6, name: RSEM_GENCODE39.transcripts.kallisto.idx}}
  paired_end: { type: 'boolean?', doc: "Set to true if reads are paired end." }

outputs:
  bam_strand_out_file: {type: File, outputSource: bam_strandness/output}
  read_length_median: {type: 'int?', outputSource: bam_strandness/read_length_median}
  read_length_stddev: {type: 'float?', outputSource: bam_strandness/read_length_stddev}
  is_paired_end: {type: 'boolean?', outputSource: bam_strandness/is_paired_end}
  rmats_strand_file: {type: File, outputSource: rmats_strand_print/rmats_strand_file}

steps:
  cram_to_bam:
    run: ../tools/samtools_cram_to_bam.cwl
    when: |
      $(inputs.input_cram.nameext != '.bam')
    in:
      input_cram: input_aligned
      reference: reference_fasta
    out: [output]
  bam_strandness:
    run: ../tools/bam_strandness.cwl
    in:
      input_bam:
        source: [cram_to_bam/output, input_aligned]
        pickValue: first_non_null
      annotation_gtf: gtf_anno
      kallisto_idx: kallisto_idx
      paired_end: paired_end
      n_reads: bam_strandness_nreads
    out: [output, strandedness, read_length_median, read_length_stddev, is_paired_end]
  rmats_strand_print:
    run: ../tools/rmats_strand_print.cwl
    in:
      strandedness:
        source: [bam_strandness/strandedness]
        pickValue: first_non_null
        valueFrom: |
          $(self == "rf-stranded" ? "fr-firststrand" : self == "fr-stranded" ? "fr-secondstrand" : "fr-unstranded")
      input_aligned:
        source: [cram_to_bam/output, input_aligned]
        pickValue: first_non_null
    out: [rmats_strand_file]

sbg:license: Apache License 2.0
sbg:publisher: KFDRC
$namespaces:
  sbg: https://sevenbridges.com
