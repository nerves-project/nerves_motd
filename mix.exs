defmodule NervesMOTD.MixProject do
  use Mix.Project

  @version "0.1.15"
  @source_url "https://github.com/nerves-project/nerves_motd"

  def project do
    [
      app: :nerves_motd,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      docs: docs(),
      description: description(),
      package: package(),
      deps: deps(),
      aliases: aliases(),
      dialyzer: dialyzer()
    ]
  end

  def application do
    []
  end

  def cli do
    [preferred_envs: %{docs: :docs, "hex.publish": :docs, "hex.build": :docs}]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:nerves_runtime, "~> 0.8"},
      {:nerves_time, "~> 0.4", optional: true},
      {:nerves_time_zones, "~> 0.1", optional: true},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false},
      {:ex_doc, "~> 0.25", only: :docs, runtime: false},
      {:mix_test_watch, "~> 1.1", only: :dev, runtime: false},
      {:igniter, "~> 0.5", only: [:dev, :test], optional: true, runtime: false},
      {:mox, "~> 1.0", only: :test}
    ]
  end

  defp docs do
    [
      extras: ["README.md", "CHANGELOG.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end

  defp description do
    "Message of the day for Nerves devices"
  end

  defp package do
    [
      files: [
        "CHANGELOG.md",
        "lib",
        "LICENSES/*",
        "mix.exs",
        "NOTICE",
        "README.md",
        "REUSE.toml"
      ],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url,
        "REUSE Compliance" =>
          "https://api.reuse.software/info/github.com/nerves-project/nerves_motd"
      }
    ]
  end

  defp aliases() do
    [
      test: "test --warnings-as-errors"
    ]
  end

  defp dialyzer() do
    [
      flags: [:missing_return, :extra_return, :unmatched_returns, :error_handling, :underspecs],
      plt_add_apps: [:nerves_time_zones, :igniter, :mix, :sourceror]
    ]
  end
end
