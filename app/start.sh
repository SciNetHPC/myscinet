#!/bin/sh
set -eu

if [ "$MIX_ENV" = "dev" ]; then
    mix deps.get --only "$MIX_ENV"
    mix compile --force
    mix assets.deploy
    mix phx.digest.clean --all
fi

SECRET_KEY_BASE=$(mix phx.gen.secret)
export SECRET_KEY_BASE

exec mix phx.server
