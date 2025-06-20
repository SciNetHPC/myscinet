# my.scinet: SciNet user portal

This is the user web portal for the SciNet supercomputing centre.
Shows information about:

- jobs
- storage
- group allocations
- overall cluster stats

The website is an [Elixir/Phoenix](https://phoenixframework.org/) app.

## Configuration environment variables

Requires the following environment variables to be defined:

```
# postgres/timescaledb job database
DATABASE_URL=ecto://username:password@hostname/database?pool_size=10
```

## Miscellaneous

Generated the phoenix app via:

```
docker run --rm -it -v ./app:/app:Z -w /app elixir:1.18-otp-27 bash -c "mix archive.install hex phx_new 1.8.0-rc.3 --force && mix phx.new . --app myscinet --module MySciNet --no-mailer --no-install && chown -R $(id -u):$(id -g) ."
```

