use Mix.Config

config :guardian, Guardian.DB, repo: GuardianRedis.Repo
# store all token types if not set
# token_types: ["refresh_token"],

config :guardian_redis, :redis,
  host: System.get_env("REDIS_HOST", "127.0.0.1"),
  port: System.get_env("REDIS_PORT", "6379"),
  pool_size: System.get_env("REDIS_POOL_SIZE", "1")
