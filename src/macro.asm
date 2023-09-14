%macro DEFINE_STRING 2
%1 db %2
%1_len equ $-%1
%endmacro
