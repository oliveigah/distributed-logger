defmodule DistributedLogger.MixProject do
  use Mix.Project

  def project do
    [
      app: :distributed_logger,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # Docs
      name: "Distributed Logger",
      source_url: "https://github.com/oliveigah/distributed-logger",
      homepage_url: "https://techfromscratch.com.br/distributed-logger",
      docs: [
        # The main page in the docs
        main: "system_overview",
        logo: "logo.png",
        extras: [
          "./system_overview.md"
        ],
        assets: "./exdocs_assets"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {DistributedLogger.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:cowboy, "~> 2.8"},
      {:plug_cowboy, "~> 2.3"},
      {:httpoison, "~> 1.7"}
    ]
  end
end
