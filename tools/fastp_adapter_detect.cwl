cwlVersion: v1.2
class: CommandLineTool
id: fastp_adapter_detect
label: "fastp v1.3.6 Adapter Detection"
doc: |
  Run fastp to detect adapter sequences and produce JSON and HTML QC reports.
  Trimmed reads are discarded (/tmp); only the reports are used downstream.
  Processes up to 1M reads by default. --detect_adapter_for_pe is added
  automatically when reads2 is provided.
  Manual adapters override detected adapters independently for each read end.
  Detected adapters are selected for cutadapt only when fastp annotates the exact
  sequence as a member of its built-in known-adapter pool. Fastp's less-than-1%
  adapter-content warning is informational and does not reject a known adapter.
  De novo or unspecified detections are rejected. Cutadapt runs when at least
  one read end has a manual or known detected adapter.
  In fastp, a single-end report omits the entire
  adapter_cutting section when no adapter is detected. Paired-end reports retain
  the section and report "unspecified" for an end where no adapter is detected.
requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'quay.io/biocontainers/fastp:1.3.6--h43da1c4_0'
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
  manual_r1_adapter:
    type: 'string?'
    doc: "User-provided R1 adapter. If present and not 'unspecified', it overrides fastp detection."
  manual_r2_adapter:
    type: 'string?'
    doc: "User-provided R2 adapter. Independently overrides R2 detection; 'unspecified' is treated as empty."
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
      && detected_r1=\$(sed -n 's/.*"read1_adapter_sequence"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' $(inputs.sample_name).fastp.json)
      && detected_r2=\$(sed -n 's/.*"read2_adapter_sequence"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' $(inputs.sample_name).fastp.json)
      && manual_r1='$(inputs.manual_r1_adapter ? inputs.manual_r1_adapter : "")'
      && manual_r2='$(inputs.manual_r2_adapter ? inputs.manual_r2_adapter : "")'
      && manual_r1=\$(printf '%s' "$manual_r1" | awk '{$1=$1; print}')
      && manual_r2=\$(printf '%s' "$manual_r2" | awk '{$1=$1; print}')
      && if [ "\$(printf '%s' "$manual_r1" | tr '[:upper:]' '[:lower:]')" = "unspecified" ]; then manual_r1=""; fi
      && if [ "\$(printf '%s' "$manual_r2" | tr '[:upper:]' '[:lower:]')" = "unspecified" ]; then manual_r2=""; fi
      && detected_r1_known=false
      && detected_r2_known=false
      && if [ -n "$detected_r1" ] && grep -Fq "$detected_r1 ->" '$(inputs.sample_name).fastp.html'; then detected_r1_known=true; fi
      && if [ -n "$(inputs.reads2 != null ? "paired" : "")" ] && [ -n "$detected_r2" ] && grep -Fq "$detected_r2 ->" '$(inputs.sample_name).fastp.html'; then detected_r2_known=true; fi
      && : > r1_adapter.txt
      && : > r2_adapter.txt
      && printf 'false\n' > run_cutadapt.txt
      && if [ -n "$manual_r1" ]; then printf '%s\n' "$manual_r1" > r1_adapter.txt; elif [ "$detected_r1_known" = true ]; then printf '%s\n' "$detected_r1" > r1_adapter.txt; fi
      && if [ -n "$(inputs.reads2 != null ? "paired" : "")" ]; then if [ -n "$manual_r2" ]; then printf '%s\n' "$manual_r2" > r2_adapter.txt; elif [ "$detected_r2_known" = true ]; then printf '%s\n' "$detected_r2" > r2_adapter.txt; fi; fi
      && if [ -s r1_adapter.txt ] || [ -s r2_adapter.txt ]; then printf 'true\n' > run_cutadapt.txt; fi

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
    doc: "Adapter selected for R1 trimming after manual override and fastp safeguards"
    outputBinding:
      glob: r1_adapter.txt
      loadContents: true
      outputEval: |
        ${
          var adapter = self[0].contents.replace(/\u0000/g, "").trim();
          return adapter && adapter.toLowerCase() !== "unspecified" ? adapter : null;
        }
  r2_adapter:
    type: 'string?'
    doc: "Adapter selected for R2 trimming after manual override and fastp safeguards"
    outputBinding:
      glob: r2_adapter.txt
      loadContents: true
      outputEval: |
        ${
          var adapter = self[0].contents.replace(/\u0000/g, "").trim();
          return adapter && adapter.toLowerCase() !== "unspecified" ? adapter : null;
        }
  run_cutadapt:
    type: boolean
    doc: "Whether cutadapt should run based on manual adapters or fastp safeguards"
    outputBinding:
      glob: run_cutadapt.txt
      loadContents: true
      outputEval: $(self[0].contents.trim() == "true")
