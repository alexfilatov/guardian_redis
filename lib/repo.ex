defmodule GuardianRedis.Repo do
  @moduledoc """
    `GuardianRedis.Repo` is a repo module that operates Guardian.DB.Token in Redis.
    The repo module serves only GuardianDb purpose, do not use it as a Redis repo for your project.
    Dependant on :jason and :redix.

    Stores and deletes JWT token to/from Redis using key combined from JWT.jti and JWT.aud.
    Module stores JWT token in Redis using automatic expiry feature of Redis so we don't need to run token sweeper.
    Anyway, `delete_all` still implemented to allow manual sweeping if needed.
  """
  @behaviour Guardian.DB.Adapter

  alias Guardian.DB.Token
  alias GuardianRedis.Redix, as: Redis

  @spec one(queryable :: Ecto.Queryable.t(), opts :: Keyword.t()) ::
          Ecto.Schema.t() | nil
  @doc """
  Fetches a single result from the query.

  Returns nil if no result was found. Raises if more than one entry.
  """
  def one(query, _opts \\ []) do
    key = key(query)

    case Redis.command(["GET", key]) do
      {:ok, nil} -> nil
      {:ok, jwt_json} -> Jason.decode!(jwt_json)
      _ -> nil
    end
  end

  @doc """
  Insert Token into Redis
  Token is auto expired in `expired_in` seconds based on JWT `exp` value
  """
  @spec insert(
          struct_or_changeset :: Ecto.Schema.t() | Ecto.Changeset.t(),
          opts :: Keyword.t()
        ) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def insert(struct, _opts \\ []) do
    key = key(struct)

    expires_in = struct.changes.exp - System.system_time(:second)
    utc_now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    token =
      struct.changes
      |> Map.put(:inserted_at, utc_now)
      |> Map.put(:updated_at, utc_now)

    case Redis.command(["SETEX", key, Integer.to_string(expires_in), Jason.encode!(token)]) do
      {:ok, "OK"} ->
        # Adding key to the set `sub` (user_id in JWT) so we can delete all user tokens in one go
        sub = sub_elem(struct)
        Redis.command(["SADD", set_name(sub), key])
        {:ok, struct(Token, token)}

      error ->
        {:error, error}
    end
  end

  @doc """
  Remove all user tokens from Redis, useful for manual sweeping
  """
  @spec delete_all(
          queryable :: Ecto.Queryable.t(),
          opts :: Keyword.t()
        ) :: {integer(), nil | [term()]}
  def delete_all(query, _opts \\ []) do
    set_name = query |> sub_elem() |> set_name()

    {:ok, keys} = Redis.command(["SMEMBERS", set_name])
    {:ok, amount_deleted} = Redis.command(["DEL", set_name] ++ keys)

    # yeah, vise-versa
    {amount_deleted - 1, :ok}
  end

  @doc """
  Remove a user token, log out functionality, invalidation of a JWT token
  """
  @spec delete(
          struct_or_changeset :: Ecto.Schema.t() | Ecto.Changeset.t(),
          opts :: Keyword.t()
        ) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def delete(model, _opts \\ []) do
    key = key(model)

    case Redis.command(["DEL", key]) do
      {:ok, _num} -> {:ok, struct(Token, model)}
      _ -> {:error, model}
    end
  end

  @doc """
  Generate Redis key from a changeset, %Token{} struct or Ecto.Query
  """
  defp key(%{changes: %{jti: jti, aud: aud}}), do: combine_key(jti, aud)
  defp key(%{"jti" => jti, "aud" => aud}), do: combine_key(jti, aud)
  defp key(query), do: combine_key(jti_elem(query), aud_elem(query))
  defp sub_elem(%{changes: %{sub: sub}}), do: sub
  defp sub_elem(%{"sub" => sub}), do: sub
  defp sub_elem(query), do: query_param(query, :sub)
  defp jti_elem(query), do: query_param(query, :jti)
  defp aud_elem(query), do: query_param(query, :aud)
  defp combine_key(jti, aud), do: "#{jti}:#{aud}"
  defp set_name(sub), do: "set:#{sub}"

  @doc """
  Retrieves params from `query.wheres` by atom name (`:jti` and `:aud` in our case), example:

  ```
  [
    %Ecto.Query.BooleanExpr{
      ...
      params: [
        {"2e024736-b4a6-4422-8b0a-4e89c7a7ebf9", {0, :jti}},
        {"my_app", {0, :aud}}
      ],
      ...
    }
  ]
  ```
  """
  defp query_param(query, param) do
    (query.wheres |> List.first()).params
    |> Enum.find(fn i -> i |> elem(1) |> elem(1) == param end)
    |> elem(0)
  end
end
