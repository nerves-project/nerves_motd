defmodule NervesMOTD.Runtime.Host do
  @moduledoc false
  @behaviour NervesMOTD.Runtime

  @apps [
    :logger,
    :hex,
    :inets,
    :ssl,
    :public_key,
    :asn1,
    :crypto,
    :mix,
    :iex,
    :elixir,
    :compiler,
    :stdlib,
    :kernel
  ]

  @impl NervesMOTD.Runtime
  def applications(), do: %{loaded: @apps, started: @apps}

  @impl NervesMOTD.Runtime
  def cpu_temperature(), do: {:ok, 41.234}

  @impl NervesMOTD.Runtime
  def firmware_valid?(), do: true

  @impl NervesMOTD.Runtime
  def load_average(), do: ["0.35", "0.16", "0.11", "2/70", "1536"]

  @impl NervesMOTD.Runtime
  def memory_stats(), do: {:ok, %{size_mb: 316, used_mb: 78, used_percent: 25}}

  @impl NervesMOTD.Runtime
  def filesystem_stats("/dev/mmcblk0p3") do
    # Raise if the path isn't the expected one for the unit tests
    {:ok, %{size_mb: 14_619, used_mb: 37, used_percent: 0}}
  end
end
