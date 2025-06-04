FROM elixir:1.18-otp-27

RUN apt-get update && apt-get install -y inotify-tools && rm -rf /var/lib/apt/lists/*
