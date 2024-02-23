# Changelog

## Unreleased
GuardianDB 3.0 changes the way the it's configuration is done.
Change
```elixir
config :guardian, Guardian.DB, repo: GuardianRedis.Repo
```
in your config to:
```elixir
config :guardian, Guardian.DB, adapter: GuardianRedis.Adapter
```
### Breaking
- bump `GuardianDB` from 2.1.1 to 3.0.0

## V0.1.0

Initial release
