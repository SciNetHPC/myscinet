FROM elixir:1.18-otp-27

ENV MIX_ENV=prod

RUN apt-get update && apt-get install -y inotify-tools && rm -rf /var/lib/apt/lists/*

# install Tidewave AI mcp-proxy
RUN cd /usr/local/bin && curl -sL https://github.com/tidewave-ai/mcp_proxy_rust/releases/latest/download/mcp-proxy-x86_64-unknown-linux-musl.tar.gz | tar xvz

COPY ./app /app
WORKDIR /app
RUN mix deps.get && \
    mix deps.compile && \
    mix assets.setup && \
    mix compile && \
    mix assets.build && \
    mix assets.deploy
CMD ["/app/start.sh"]
