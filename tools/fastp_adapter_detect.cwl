cwlVersion: v1.2
class: CommandLineTool
id: fastp_adapter_detect
label: "fastp v0.23.4 Adapter Detection"
doc: |
  Run fastp to detect adapter sequences and produce JSON and HTML QC reports.
  Trimmed reads are discarded (/tmp); only the reports are used downstream.
  Processes up to 1M reads by default. --detect_adapter_for_pe is added
  automatically when reads2 is provided.
requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'quay.io/biocontainers/fastp:0.23.4--h5f740d0_0'
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: $(inputs.threads)
    ramMin: 4000

baseCommand: [fastp]

inputs:
  reads1:
    type: File
    doc: "R1 FASTQ (or FASTQ.GZ) file"
    inputBinding:
      prefix: "-i"
      position: 1
  reads2:
    type: 'File?'
    doc: "R2 FASTQ (or FASTQ.GZ) file for paired-end input"
    inputBinding:
      prefix: "-I"
      position: 2
  sample_name:
    type: string
    doc: "Sample name used to name output reports"
  threads:
    type: 'int?'
    default: 4
    inputBinding:
      prefix: "--thread"
      position: 3
  reads_to_process:
    type: 'int?'
    default: 1000000
    doc: "Limit number of reads analysed (speeds up detection)"
    inputBinding:
      prefix: "--reads_to_process"
      position: 4

arguments:
  - position: 5
    shellQuote: false
    valueFrom: |
      ${
        var flags = "";
        if (inputs.reads2 != null) {
          flags += "--detect_adapter_for_pe";
        }
        return flags;
      }
  - position: 6
    shellQuote: false
    valueFrom: |
      ${
        var cmd = "-h " + inputs.sample_name + ".fastp.html -j " + inputs.sample_name + ".fastp.json -o /tmp/fastp_discard_r1.fastq.gz";
        if (inputs.reads2 != null) {
          cmd += " -O /tmp/fastp_discard_r2.fastq.gz";
        }
        return cmd;
      }

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
