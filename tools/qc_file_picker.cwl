cwlVersion: v1.2
class: ExpressionTool
id: qc_file_picker
requirements:
  - class: InlineJavascriptRequirement

inputs:
  strandedness: 'string?'
  stranded_file: 'File'
  unstranded_file: 'File'

outputs:
  qc_file:
    type: string

expression: |
  ${
    var qc_file = inputs.strandedness ? inputs.stranded_file : inputs.unstranded_file;
    return {
      qc_file
    }
  }
