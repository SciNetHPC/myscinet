Definitions.

WHITESPACE = [\s\t\n\r]+
NUMBER     = [0-9]+
IDENT      = [a-zA-Z_][a-zA-Z0-9_-]*
BARESTR    = [^"%:<=>\s\t\n\r]+
QUOTESTR   = "[^"%]*"

Rules.

{WHITESPACE} : skip_token.
{NUMBER}     : {token, {number, list_to_integer(TokenChars)}}.
{IDENT}      : {token, {ident, list_to_atom(TokenChars)}}.
{BARESTR}    : {token, {string, list_to_binary(TokenChars)}}.
{QUOTESTR}   : {token, {string, list_to_binary(drop_first_and_last(TokenChars))}}.
\:           : {token, {':'}}.
\<           : {token, {'<'}}.
\<\=         : {token, {'<='}}.
\>           : {token, {'>'}}.
\>\=         : {token, {'>='}}.

Erlang code.

drop_first_and_last([_First | Rest]) ->
    lists:droplast(Rest).