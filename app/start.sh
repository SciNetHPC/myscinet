#!/bin/sh
set -eu

if [ ! -f /.setup_done ]; then
    mix setup
    touch /.setup_done
else
    mix deps.get --only "$MIX_ENV"
    mix compile
    mix assets.deploy
fi
mix phx.digest.clean --all

SECRET_KEY_BASE=$(mix phx.gen.secret)
export SECRET_KEY_BASE

exec mix phx.server
