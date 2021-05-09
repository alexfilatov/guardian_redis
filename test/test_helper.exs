Supervisor.start_link([GuardianRedis.Redix.child_spec([])], strategy: :one_for_one)
ExUnit.start()
