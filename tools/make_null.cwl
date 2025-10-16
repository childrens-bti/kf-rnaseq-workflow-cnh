cwlVersion: v1.2
class: ExpressionTool

id: make_null
requirements:
  - class: InlineJavascriptRequirement

inputs:
  input_files:
    type: File[]

outputs:
  output:
    type: 'File[]?'

expression: |
  ${
    function checkAllNull(arr) {
        if (arr.length === 0) {
            return null; 
            }
        const allAreNull = arr.every(item => item === null);
        return allAreNull ? null : arr;
    }
    return {"output": checkAllNull(inputs.input_files)}
  }