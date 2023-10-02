defmodule GuardianRedis.AdapterTest do
  use ExUnit.Case
  alias Guardian.DB.Token

  @doc """
  token-uuid:token - Redis key combined from `jti` and `aud`
  """
  def get_token(key \\ "token-uuid:token") do
    case GuardianRedis.Redix.command(["GET", key]) do
      {:ok, nil} -> nil
      {:ok, jwt_json} -> Jason.decode!(jwt_json)
      _ -> nil
    end
  end

  setup do
    GuardianRedis.Redix.command(["FLUSHDB"])

    claims = %{
      "jti" => "token-uuid",
      "typ" => "token",
      "aud" => "token",
      "sub" => "initial_the_subject",
      "iss" => "initial_the_issuer",
      "exp" => Guardian.timestamp() + 1_000_000_000
    }

    {:ok, %{claims: claims}}
  end

  test "after_encode_and_sign_in is successful", context do
    token = get_token()

    assert token == nil

    Guardian.DB.after_encode_and_sign(%{}, "token", context.claims, "The JWT")

    token = get_token()

    assert token != nil
    assert token["jti"] == "token-uuid"
    assert token["aud"] == "token"
    assert token["sub"] == "initial_the_subject"
    assert token["iss"] == "initial_the_issuer"
    assert token["exp"] == context.claims["exp"]
    assert token["claims"] == context.claims
  end

  test "on_verify with a record in the db", context do
    Token.create(context.claims, "The JWT")
    token = get_token()
    assert token != nil

    assert {:ok, {context.claims, "The JWT"}} == Guardian.DB.on_verify(context.claims, "The JWT")
  end

  test "on_verify without a record in the db", context do
    token = get_token()
    assert token == nil
    assert {:error, :token_not_found} == Guardian.DB.on_verify(context.claims, "The JWT")
  end

  test "on_refresh without a record in the db", context do
    token = get_token()
    assert token == nil

    Guardian.DB.after_encode_and_sign(%{}, "token", context.claims, "The JWT 1")
    old_stuff = {get_token(), context.claims}
    assert get_token() != nil

    new_claims = %{
      "jti" => "token-uuid1",
      "typ" => "token",
      "aud" => "token",
      "sub" => "the_subject",
      "iss" => "the_issuer",
      "exp" => Guardian.timestamp() + 2_000_000_000
    }

    Guardian.DB.after_encode_and_sign(%{}, "token", new_claims, "The JWT 2")
    new_stuff = {get_token("token-uuid1:token"), new_claims}
    assert get_token("token-uuid1:token") != nil

    assert Guardian.DB.on_refresh(old_stuff, new_stuff) == {:ok, old_stuff, new_stuff}
  end

  test "on_revoke without a record in the db", context do
    token = get_token()
    assert token == nil
    assert Guardian.DB.on_revoke(context.claims, "The JWT") == {:ok, {context.claims, "The JWT"}}
  end

  test "on_revoke with a record in the db", context do
    Token.create(context.claims, "The JWT")

    {:ok, keys} = GuardianRedis.Redix.command(["KEYS", "*"])
    assert Enum.sort(keys) == ["set:initial_the_subject", "token-uuid:token"]

    token = get_token()

    assert token != nil

    assert Guardian.DB.on_revoke(context.claims, "The JWT") == {:ok, {context.claims, "The JWT"}}

    token = get_token()
    assert token == nil
  end

  describe "delete_by_sub/2" do
    test "deletes all tokens of a sub" do
      sub = "the_subject"

      Token.create(
        %{
          "jti" => "token1",
          "aud" => "token",
          "exp" => Guardian.timestamp() + 5000,
          "sub" => sub
        },
        "Token 1"
      )

      Token.create(
        %{
          "jti" => "token2",
          "aud" => "token",
          "exp" => Guardian.timestamp() + 5000,
          "sub" => sub
        },
        "Token 2"
      )

      Token.create(
        %{
          "jti" => "token3",
          "aud" => "token",
          "exp" => Guardian.timestamp() + 5000,
          "sub" => sub
        },
        "Token 3"
      )

      assert {:ok, 3} = Guardian.DB.revoke_all(sub)
      assert {:ok, []} = GuardianRedis.Redix.command(["KEYS", "*"])
    end

    test "doesn't affect tokens from a different sub" do
      sub = "the_subject"

      Token.create(
        %{
          "jti" => "token1",
          "aud" => "token",
          "exp" => Guardian.timestamp() + 5000,
          "sub" => sub
        },
        "Token 1"
      )

      sub_2 = "another_subject"

      Token.create(
        %{
          "jti" => "token2",
          "aud" => "token",
          "exp" => Guardian.timestamp() + 5000,
          "sub" => sub_2
        },
        "Token 2"
      )

      assert {:ok, 1} = Guardian.DB.revoke_all(sub)
      assert {:ok, keys} = GuardianRedis.Redix.command(["KEYS", "*"])
      assert ["set:#{sub_2}", "token2:token"] == keys
    end
  end

  test "purge_expired_tokens/2 can be called" do
    assert {0, nil} = Guardian.DB.Token.purge_expired_tokens()
  end
end
