cwlVersion: v1.2
class: Workflow
id: build_star_rsem_kallisto_references
label: "build_star_rsem_kallisto_references"
doc: |
  Build references for STAR, RSEM, and Kallisto for GRCm39

requirements:
  - class: InlineJavascriptRequirement

inputs:
  reference_fasta:
    type: File
    doc: "Reference FASTA file (e.g., GRCm39.primary_assembly.genome.fa)"
  reference_name:
    type: string
    doc: "RSEM output prefix, e.g., RSEM_GRCm39"
  reference_gtf:
    type: File?
    doc: "Gene model (GTF). Use this OR GFF3."
  reference_gff:
    type: File?
    doc: "Gene model (GFF3). Use this OR GTF."
  transcript_idx:
    type: string
    doc: "Kallisto index filename to CREATE"
    default: "kallisto_GRCm39.idx"
  sjdbOverhang:
    type: int?
    default: 100
  runThreadN:
    type: int?
    default: 16
  genomeDir:
    type: string?
    default: "star_index_GRCm39"

outputs:
  rsem_reference_file:
    type: File
    outputSource: rsem_prepare_reference/rsem_reference
  kallisto_index_output:
    type: File
    outputSource: kallisto_index/index_out
  star_index_output:
    type: File
    outputSource: star_index/star_ref

steps:
  rsem_prepare_reference:
    run: ../tools/rsem_prepare_reference.cwl
    in:
      reference_fasta: reference_fasta
      reference_name: reference_name
      reference_gff: reference_gff
      reference_gtf: reference_gtf
      out: [rsem_reference, rsem_transcripts_fa, rsem_fasta]   

  kallisto_index:
    run: ../tools/kallisto_index.cwl
    in:
      transcript_idx: transcript_idx
      transcript_fasta: rsem_prepare_reference/rsem_transcripts_fa 
    out: [index_out]

  star_index:
    run: ../tools/star_2.7.10a_genome_generate.cwl
    in:
      genome_fa: reference_fasta
      gtf: reference_gtf
      sjdbOverhang: sjdbOverhang
      genomeDir: genomeDir
      runThreadN: runThreadN
    out: [star_ref]

