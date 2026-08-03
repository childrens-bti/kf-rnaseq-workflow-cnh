cwlVersion: v1.2
class: ExpressionTool
id: qc_file_picker
requirements:
  - class: InlineJavascriptRequirement

inputs:
  strandedness: string
  stranded_file: 'File'
  unstranded_file: 'File'

outputs:
  qc_file:
    type: string

expression: |
  ${
    var qc_file = inputs.strandedness == "default" ? inputs.unstranded_file : inputs.stranded_file;
    return {
      qc_file
    }
  }
