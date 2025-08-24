
Nonterminals
    filter
    filters
    name
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
root -> filters : '$1'.

filters -> filter : ['$1'].
filters -> filter filters : ['$1'|'$2'].

filter -> name ':' value : {is_eq, '$1', '$3'}.
filter -> name '>'  value : {is_gt, '$1', '$3'}.
filter -> name '>=' value : {is_ge, '$1', '$3'}.
filter -> name '<'  value : {is_lt, '$1', '$3'}.
filter -> name '<=' value : {is_le, '$1', '$3'}.
filter -> number : '$1'.
filter -> ident : '$1'.
filter -> string : '$1'.

name -> ident : element(2, '$1').

value -> number : '$1'.
value -> ident  : '$1'.
value -> string : '$1'.

Erlang code.
