
Nonterminals
    filter
    filters
    name
    num
    root
    value
.

Terminals
    ':'
    '<'
    '<='
    '>'
    '>='
    ident
    number
    string
.

Rootsymbol root.

root -> '$empty' : [].
root -> value : '$1'.
root -> filters : '$1'.

filters -> filter : ['$1'].
filters -> filter filters : ['$1'|'$2'].

filter -> name ':' value : {is_eq, '$1', '$3'}.
filter -> name '>'  num : {is_gt, '$1', '$3'}.
filter -> name '>=' num : {is_ge, '$1', '$3'}.
filter -> name '<'  num : {is_lt, '$1', '$3'}.
filter -> name '<=' num : {is_le, '$1', '$3'}.

name -> ident : element(2, '$1').
num -> number : element(2, '$1').

value -> number : element(2, '$1').
value -> ident  : element(2, '$1').
value -> string : element(2, '$1').

Erlang code.
