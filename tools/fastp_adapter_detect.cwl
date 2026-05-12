cwlVersion: v1.2
class: CommandLineTool
id: fastp_adapter_detect
label: "fastp v0.23.4 Adapter Detection"
doc: |
  Run fastp to detect adapter sequences and produce JSON and HTML QC reports.
  Trimmed reads are discarded (/tmp); only the reports are used downstream.
  Processes up to 1M reads by default. --detect_adapter_for_pe is added
  automatically when reads2 is provided.
  Adapter sequences are extracted from the fastp JSON to plain text files
  (r1_adapter.txt, r2_adapter.txt) so downstream steps can consume them
  without relying on JSON parsing inside CWL expressions (which fails on
  engines that truncate loadContents to 64 KiB).
requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'quay.io/biocontainers/fastp:0.23.4--h5f740d0_0'
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: $(inputs.threads)
    ramMin: 4000

baseCommand: []

inputs:
  reads1:
    type: File
    doc: "R1 FASTQ (or FASTQ.GZ) file"
    inputBinding:
      prefix: "-i"
      position: 2
  reads2:
    type: 'File?'
    doc: "R2 FASTQ (or FASTQ.GZ) file for paired-end input"
    inputBinding:
      prefix: "-I"
      position: 3
  sample_name:
    type: string
    doc: "Sample name used to name output reports"
  threads:
    type: 'int?'
    default: 4
    inputBinding:
      prefix: "--thread"
      position: 4
  reads_to_process:
    type: 'int?'
    default: 1000000
    doc: "Limit number of reads analysed (speeds up detection)"
    inputBinding:
      prefix: "--reads_to_process"
      position: 5

arguments:
  - position: 1
    shellQuote: false
    valueFrom: "fastp"
  - position: 6
    valueFrom: |
      $(inputs.reads2 != null ? "--detect_adapter_for_pe" : null)
  - position: 7
    prefix: "-h"
    valueFrom: $(inputs.sample_name + ".fastp.html")
  - position: 8
    prefix: "-j"
    valueFrom: $(inputs.sample_name + ".fastp.json")
  - position: 9
    prefix: "-o"
    valueFrom: /tmp/fastp_discard_r1.fastq.gz
  - position: 10
    prefix: "-O"
    valueFrom: |
      $(inputs.reads2 != null ? "/tmp/fastp_discard_r2.fastq.gz" : null)
  - position: 100
    shellQuote: false
    valueFrom: >-
      && sed -n 's/.*"read1_adapter_sequence"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' $(inputs.sample_name).fastp.json > r1_adapter.txt
      && sed -n 's/.*"read2_adapter_sequence"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' $(inputs.sample_name).fastp.json > r2_adapter.txt

outputs:
  fastp_json:
    type: File
    doc: "fastp JSON report with detected adapter sequences and QC metrics"
    outputBinding:
      glob: $(inputs.sample_name).fastp.json
  fastp_html:
    type: File
    doc: "fastp HTML report"
    outputBinding:
      glob: $(inputs.sample_name).fastp.html
  r1_adapter:
    type: 'string?'
    doc: "Detected R1 adapter sequence (empty file => null)"
    outputBinding:
      glob: r1_adapter.txt
      loadContents: true
      outputEval: $(self[0].contents.trim() || null)
  r2_adapter:
    type: 'string?'
    doc: "Detected R2 adapter sequence (empty file => null)"
    outputBinding:
      glob: r2_adapter.txt
      loadContents: true
      outputEval: $(self[0].contents.trim() || null)
