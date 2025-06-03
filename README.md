# my.scinet

Generated the phoenix app via:

```
docker run --rm -it -v ./app:/app:Z -w /app elixir:1.18-otp-27 bash -c "mix archive.install hex phx_new 1.8.0-rc.3 --force && mix phx.new . --app myscinet --module MySciNet --no-mailer --no-install && chown -R $(id -u):$(id -g) ."
```

