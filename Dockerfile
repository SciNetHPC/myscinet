FROM elixir:1.18-otp-27

ENV MIX_ENV=prod

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        inotify-tools \
        python3 \
        python3-pip \
        python3-venv \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /venv \
    && /venv/bin/pip3 install --no-cache-dir --upgrade pip \
    && /venv/bin/pip3 install --no-cache-dir duckdb vastdb
COPY scripts/vast_usage_by_user.py /venv/bin/

# install Tidewave AI mcp-proxy
#RUN cd /usr/local/bin && curl -sL https://github.com/tidewave-ai/mcp_proxy_rust/releases/latest/download/mcp-proxy-x86_64-unknown-linux-musl.tar.gz | tar xvz

COPY ./app /app
WORKDIR /app
RUN mix deps.get && \
    mix deps.compile && \
    mix assets.setup && \
    mix compile && \
    mix assets.build && \
    mix assets.deploy
CMD ["/app/start.sh"]
