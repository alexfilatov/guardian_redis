defmodule GuardianRedis.Redix do
  @moduledoc """
  Redix module.

  ### Configuration
  Configuration options are the same as in `Redix.start_link/1`, except for
  `pool_size`, `name_prefix`, and `name`.

  - `pool_size` - determines how many Redix connections are created; defaults to `1`
  - `name_prefix` - the prefix used in `name`; defaults to `"guardian_redis"`

  The `name` option is overwritten based on the given `name_prefix` and `pool_size`.
  In the case of the example below, `name` would be `:g_redis_0` for the first
  Redis connection, and `:g_redis_1` for the second.

  ```
  config :guardian_redis, :redis,
    host: "127.0.0.1",
    port: 6379,
    pool_size: 2,
    name_prefix: "g_redis"
  ```
  """
  @default_redis_name_prefix "guardian_redis"
  @default_redis_pool_size 1

  @doc """
  Specs for the Redix connections.
  """
  def child_spec(_args) do
    config = Keyword.drop(redis_config(), [:pool_size, :name_prefix, :name])
    name_prefix = name_prefix()

    children =
      for index <- 0..(pool_size() - 1) do
        args = Keyword.put(config, :name, :"#{name_prefix}_#{index}")

        Supervisor.child_spec({Redix, args}, id: {Redix, index})
      end

    %{
      id: RedixSupervisor,
      type: :supervisor,
      start: {Supervisor, :start_link, [children, [strategy: :one_for_one]]}
    }
  end

  @doc """
  Redis commands execution via pool of Redix workers
  command_params - List of String commands, e.g. ["GET", "redis_key"]

  ## Examples

      iex> GuardianRedis.Redix.command(["SET", "key", "value"])
      {:ok, "OK"}
      iex> GuardianRedis.Redix.command(["GET", "key"])
      {:ok, "value"}
  """
  @spec command(command_params :: list(any())) ::
          {:ok, Redix.Protocol.redis_value()}
          | {:error, atom() | Redix.Error.t() | Redix.ConnectionError.t()}
  def command(command_params) do
    Redix.command(:"#{name_prefix()}_#{random_index()}", command_params)
  end

  defp random_index do
    Enum.random(0..(pool_size() - 1))
  end

  defp pool_size do
    Keyword.get(redis_config(), :pool_size, @default_redis_pool_size)
  end

  defp name_prefix do
    Keyword.get(redis_config(), :name_prefix, @default_redis_name_prefix)
  end

  defp redis_config do
    Application.get_env(:guardian_redis, :redis, [])
  end
end
