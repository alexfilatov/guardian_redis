use Mix.Config

config :guardian, Guardian.DB, repo: Guardian.Redis.Repo

config :guardian_redis, :redis,
  host: {:system, "REDIS_HOST"},
  port: {:system, "REDIS_PORT"}
