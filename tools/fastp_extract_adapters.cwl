cwlVersion: v1.2
class: CommandLineTool
id: fastp_extract_adapters
label: "Extract adapter sequences from fastp JSON"
doc: |
  Parse a fastp JSON report and emit detected adapter sequences for R1/R2.
  Empty values are returned as null.
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entryname: fastp.json
        entry: $(inputs.fastp_json)
      - entryname: parse_fastp_json.py
        entry: |
          #!/usr/bin/env python3
          import json

          with open("fastp.json", "r", encoding="utf-8") as fh:
              data = json.load(fh)

          ac = data.get("adapter_cutting", {}) if isinstance(data, dict) else {}

          r1 = ac.get("read1_adapter_sequence", "")
          r2 = ac.get("read2_adapter_sequence", "")

          with open("r1_adapter.txt", "w", encoding="utf-8") as out1:
              out1.write(r1)
          with open("r2_adapter.txt", "w", encoding="utf-8") as out2:
              out2.write(r2)
  - class: DockerRequirement
    dockerPull: 'python:3.11-slim'

baseCommand: [python3, parse_fastp_json.py]

inputs:
  fastp_json:
    type: File
    doc: "fastp JSON report"

outputs:
  r1_adapter:
    type: 'string?'
    outputBinding:
      glob: r1_adapter.txt
      loadContents: true
      outputEval: |
        ${
          var v = self[0].contents.trim();
          return v.length > 0 ? v : null;
        }
  r2_adapter:
    type: 'string?'
    outputBinding:
      glob: r2_adapter.txt
      loadContents: true
      outputEval: |
        ${
          var v = self[0].contents.trim();
          return v.length > 0 ? v : null;
        }
