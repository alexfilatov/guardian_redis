defmodule GuardianRedisTest do
  use ExUnit.Case
  doctest GuardianRedis

  test "greets the world" do
    assert GuardianRedis.hello() == :world
  end
end
