# GuardianRedis

Redis repository for Guardian DB. 

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

All you need to do is to use [configuration from Guardian.DB](https://github.com/ueberauth/guardian_db#readme) 
and just use `GuardianRedis.Repo` as a `repo` in settings.  

```elixir
config :guardian, Guardian.DB,
       repo: GuardianRedis.Repo # Add this Redis repository module
```

## Implement a repo for a different storage

Initially, Guardian.DB was aimed to store and operate JWT tokens in a PostgreSQL database. 
Sometimes round trip to Postgres database is expensive so this is why this Redis repo was born.
In case you want to implement a possibility for Guardian.DB to use different storage, e.g. ETS (or MySQL), 
you need to implement `Guardian.DB.Adapter` behavior. Thanks to [@aleDsz](https://github.com/aleDsz) it's quite simple:

```elixir
defmodule Guardian.DB.Adapter do
  @moduledoc """
  The Guardian DB Adapter.

  This behaviour allows to use any storage system
  for Guardian Tokens.
  """

  @typep query :: Ecto.Query.t()
  @typep schema :: Ecto.Schema.t()
  @typep schema_or_changeset :: schema() | Ecto.Changeset.t()
  @typep queryable :: query() | schema()
  @typep opts :: keyword()
  @typep id :: pos_integer() | binary() | Ecto.UUID.t()

  @callback one(queryable()) :: nil | schema()
  @callback get(queryable(), id()) :: nil | schema()
  @callback insert(schema_or_changeset()) :: {:ok, schema()}
  @callback delete(schema_or_changeset()) :: {:ok, schema()}
  @callback delete_all(queryable()) :: {:ok, pos_integer()}
  @callback delete_all(queryable(), opts()) :: {:ok, pos_integer()}
end
```


Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/guardian_redis](https://hexdocs.pm/guardian_redis).

