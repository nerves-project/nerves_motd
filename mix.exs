defmodule NervesMOTD.MixProject do
  use Mix.Project

  @version "0.1.4"
  @source_url "https://github.com/nerves-project/nerves_motd"

  def project do
    [
      app: :nerves_motd,
      version: @version,
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      docs: docs(),
      description: description(),
      package: package(),
      deps: deps(),
      dialyzer: dialyzer(),
      preferred_cli_env: %{
        docs: :docs,
        "hex.publish": :docs,
        "hex.build": :docs
      }
    ]
  end

  def application do
    []
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:nerves_runtime, "~> 0.8"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.25", only: :docs, runtime: false},
      {:mix_test_watch, "~> 1.1", only: :dev, runtime: false},
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
      files: ["CHANGELOG.md", "lib", "LICENSE", "mix.exs", "README.md"],
      licenses: ["Apache-2.0"],
      links: %{"Github" => @source_url}
    ]
  end

  defp dialyzer() do
    [
      flags: [:race_conditions, :unmatched_returns, :error_handling, :underspecs]
    ]
  end
end
