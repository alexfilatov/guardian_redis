use Mix.Config

config :guardian, Guardian.DB,
  # Add your repository module
  repo: GuardianRedis.Repo,
  # default: 60 minutes
  sweep_interval: 60

# store all token types if not set
# token_types: ["refresh_token"],

config :guardian_redis, :redis,
  host: "127.0.0.1",
  port: 6379,
  pool_size: 10
