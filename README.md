# GuardianRedis

[![Hex.pm](https://img.shields.io/hexpm/v/guardian_redis.svg)](https://hex.pm/packages/guardian_redis)
![Build Status](https://github.com/alexfilatov/guardian_redis/workflows/Continuous%20Integration/badge.svg)

Redis adapter for Guardian DB.

## Installation

You can use `GuardianRedis` in case you use [Guardian](https://github.com/ueberauth/guardian) library for authentication
and [Guardian.DB](https://github.com/ueberauth/guardian_db) library for JWT tokens persistence.

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `guardian_redis` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:guardian_redis, "~> 0.1.0"}
  ]
end
```


## Configuration

All you need to install Guardian DB as per [Guardian.DB README](https://github.com/ueberauth/guardian_db#readme)
and just use `GuardianRedis.Adapter` as a `adapter` in settings.

```elixir
config :guardian, Guardian.DB,
       adapter: GuardianRedis.Adapter # Add this Redis adapter module
```

Add GuardianRedis.Redix to your supervision tree:

(Note: If this is not configured you will get a `no process` error when storing or revoking tokens!)

```elixir
defmodule MyApp.Application do

  # ...

  defp my_app_otp_apps() do
    children = [
      MyApp.Repo,
      GuardianRedis.Redix
    ]
  end
end
```

Apart from this please set up Redis configuration:

```elixir
config :guardian_redis, :redis,
  host: "127.0.0.1",
  port: 6379,
  pool_size: 10
```


## Implement Guardian.DB adapter for a different storage

Initially, Guardian.DB was aimed to store and operate JWT tokens in a PostgreSQL database.
Sometimes round trip to Postgres database is expensive so this is why this Redis adapter was born.
In case you want to implement a possibility for Guardian.DB to use different storage, e.g. ETS (or MySQL),
you need to implement `Guardian.DB.Adapter` behavior. Thanks to [@aleDsz](https://github.com/aleDsz) it's quite simple:
https://github.com/ueberauth/guardian_db/blob/master/lib/guardian/db/adapter.ex

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/guardian_redis](https://hexdocs.pm/guardian_redis).

