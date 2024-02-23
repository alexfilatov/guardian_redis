defmodule GuardianRedis.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/alexfilatov/guardian_redis"

  def project do
    [
      name: "GuardianRedis",
      app: :guardian_redis,
      version: @version,
      description: "Redis adapter for Guardian DB",
      elixir: "~> 1.4 or ~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      docs: docs(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:guardian_db, "~> 3.0"},
      {:redix, "~> 1.1"},
      {:jason, "~> 1.1"},

      # Tools
      {:dialyxir, ">= 0.0.0", only: [:dev], runtime: false},
      {:credo, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:excoveralls, ">= 0.0.0", only: [:test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: [:dev], runtime: false},
      {:inch_ex, ">= 0.0.0", only: [:dev], runtime: false},
      {:plug, "~> 1.10", only: [:dev, :test], runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp docs do
    [
      main: "readme",
      homepage_url: @source_url,
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["README.md"]
    ]
  end

  defp package do
    [
      maintainers: ["Alex Filatov"],
      licenses: ["MIT"],
      links: %{GitHub: @source_url},
      files: [
        "lib",
        "CHANGELOG.md",
        "LICENSE",
        "mix.exs",
        "README.md"
      ]
    ]
  end
end
