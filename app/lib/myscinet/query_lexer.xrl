Definitions.

WHITESPACE = [\s\t\n\r]+
NUMBER     = [0-9]+
IDENT      = [a-zA-Z_][a-zA-Z0-9_-]*

Rules.

{WHITESPACE} : skip_token.
{NUMBER}     : {token, {number, list_to_integer(TokenChars)}}.
{IDENT}      : {token, {ident, list_to_atom(TokenChars)}}.
\:           : {token, {':'}}.
\<           : {token, {'<'}}.
\<\=         : {token, {'<='}}.
\>           : {token, {'>'}}.
\>\=         : {token, {'>='}}.

Erlang code.
