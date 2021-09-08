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
  def firmware_valid?(), do: true

  @impl NervesMOTD.Runtime
  def load_average(), do: ["0.35", "0.16", "0.11", "2/70", "1536"]

  @impl NervesMOTD.Runtime
  def memory_usage(), do: [316_664, 78_408, 126_776, 12, 111_480, 238_564]
end
