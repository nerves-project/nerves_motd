defmodule NervesMOTD.MixProject do
  use Mix.Project

  @version "0.1.13"
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
      compilers: [:tip_compiler | Mix.compilers()],
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
      {:nerves_time, "~> 0.4", optional: true},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.25", only: :docs, runtime: false},
      {:mix_test_watch, "~> 1.1", only: :dev, runtime: false},
      {:mox, "~> 1.0", only: :test}
    ] ++ maybe_nerves_time_zones()
  end

  if Version.match?(System.version(), ">= 1.11.0") do
    defp maybe_nerves_time_zones() do
      [{:nerves_time_zones, "~> 0.1", optional: true}]
    end
  else
    defp maybe_nerves_time_zones(), do: []
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
      files: ["CHANGELOG.md", "lib", "LICENSE", "mix.exs", "README.md", "tips"],
      licenses: ["Apache-2.0"],
      links: %{"Github" => @source_url}
    ]
  end

  defp dialyzer() do
    [
      flags: [:missing_return, :extra_return, :unmatched_returns, :error_handling, :underspecs],
      plt_add_apps: [:nerves_time_zones]
    ]
  end
end

defmodule Mix.Tasks.Compile.TipCompiler do
  use Mix.Task

  @recursive true

  def run(_args) do
    File.ls!("tips")
    |> Enum.each(&process_file/1)
  end

  defp process_file(file) do
    priv_path = Path.join(Mix.Project.app_path(), "priv")
    File.mkdir_p!(priv_path)

    source_strings = File.read!("tips/#{file}")
    divider = "\n%\n"
    divider_byte_size = byte_size(divider)

    {indices, _} =
      source_strings
      |> String.split(divider)
      |> Enum.reduce({[], 0}, fn tip, {indices, current_location} ->
        how_many_bytes = byte_size(tip)
        next_location = current_location + how_many_bytes + divider_byte_size
        new_index = {current_location, how_many_bytes}

        {[new_index | indices], next_location}
      end)

    result = :erlang.term_to_binary(indices)

    strings_file = Path.join(priv_path, file)
    index_file = Path.join(priv_path, "#{file}.index")
    File.write!(strings_file, source_strings)
    File.write!(index_file, result)
  end
end
