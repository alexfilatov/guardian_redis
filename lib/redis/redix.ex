defmodule Guardian.Redis.Redix do
  @default_redis_host "127.0.0.1"
  @default_redis_port 6379
  @default_redis_pool_size 1

  def child_spec(_args) do
    # Specs for the Redix connections.
    children =
      for index <- 0..(pool_size() - 1) do
        Supervisor.child_spec(
          {Redix, name: :"redix_#{index}", host: redis_host(), port: redis_port()},
          id: {Redix, index}
        )
      end

    %{
      id: RedixSupervisor,
      type: :supervisor,
      start: {Supervisor, :start_link, [children, [strategy: :one_for_one]]}
    }
  end

  def command(command) do
    Redix.command(:"redix_#{random_index()}", command)
  end

  defp redis_host do
    redis_config[:host] || @default_redis_host
  end

  defp redis_port do
    (redis_config[:port] || @default_redis_port) |> String.to_integer()
  end

  defp pool_size do
    redis_config[:pool_size] || @default_redis_pool_size
  end

  defp redis_config do
    Application.get_env(:guardian_redis, :redis)
  end

  defp random_index() do
    Enum.random(0..(pool_size() - 1))
  end
end
