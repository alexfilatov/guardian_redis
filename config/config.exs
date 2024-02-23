use Mix.Config

config :guardian, Guardian.DB, adapter: GuardianRedis.Adapter

config :guardian_redis, :redis,
  host: System.get_env("REDIS_HOST", "127.0.0.1"),
  port: String.to_integer(System.get_env("REDIS_PORT", "6379")),
  pool_size: String.to_integer(System.get_env("REDIS_POOL_SIZE", "1"))
