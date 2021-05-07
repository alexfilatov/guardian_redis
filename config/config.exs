use Mix.Config

config :guardian, Guardian.DB,
  # Add your repository module
  repo: Guardian.Redis.Repo,
  # store all token types if not set
  token_types: ["refresh_token"],
  # default: 60 minutes
  sweep_interval: 60

config :guardian_redis, :redis,
  host: {:system, "REDIS_HOST"},
  port: {:system, "REDIS_PORT"},
  pool_size: 10
