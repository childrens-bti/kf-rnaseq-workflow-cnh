cwlVersion: v1.2
class: CommandLineTool
id: rnaseqc_gtf_collapse
label: "Collapse GTF for RNA-SeQC (GTEx script, stranded & unstranded)"

requirements:
  - class: DockerRequirement
    dockerPull: pgc-images.sbgenomics.com/d3b-bixu/toolkit_python:3.0.0
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement

baseCommand: [bash, -lc]

inputs:
  gtf:
    type: File
    doc: "Input GTF (GENCODE recommended; matching your genome)"
  out_name_unstranded:
    type: string
    doc: "Output filename for unstranded collapsed GTF"
  out_name_stranded:
    type: string
    doc: "Output filename for stranded collapsed GTF"

arguments:
  - position: 1
    valueFrom: |
      set -euo pipefail
      export PIP_ROOT_USER_ACTION=ignore

      # Install deps
      python3 -m pip -q install --no-cache-dir numpy pandas bx-python >/dev/null

      # Fetch collapse_annotation.py 
      python3 - <<'PY'
      import os, shlex, subprocess, urllib.request

      gtf      = r"$(inputs.gtf.path)"
      out_un   = r"$(inputs.out_name_unstranded)"
      out_str  = r"$(inputs.out_name_stranded)"

      url = "https://raw.githubusercontent.com/broadinstitute/gtex-pipeline/master/gene_model/collapse_annotation.py"
      urllib.request.urlretrieve(url, "collapse_annotation.py")

      # Unstranded
      cmd_un = ["python3", "collapse_annotation.py", gtf, "collapsed_un.gtf"]
      print("Running:", " ".join(shlex.quote(c) for c in cmd_un), flush=True)
      subprocess.check_call(cmd_un)
      os.replace("collapsed_un.gtf", out_un)

      # Stranded
      cmd_str = ["python3", "collapse_annotation.py", "--stranded", gtf, "collapsed_str.gtf"]
      print("Running:", " ".join(shlex.quote(c) for c in cmd_str), flush=True)
      subprocess.check_call(cmd_str)
      os.replace("collapsed_str.gtf", out_str)
      PY

outputs:
  out_gtf_unstranded:
    type: File
    outputBinding:
      glob: $(inputs.out_name_unstranded)
  out_gtf_stranded:
    type: File
    outputBinding:
      glob: $(inputs.out_name_stranded)

