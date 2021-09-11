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

  @impl NervesMOTD.Runtime
  def sd_card() do
    %{
      "/dev/mmcblk0p1" => ["19", "6", "13", "32%", "/boot"],
      "/dev/mmcblk0p3" => ["14619", "37", "13821", "0%", "/root"],
      "/dev/root" => ["39", "39", "0", "100%", "/"],
      "devtmpfs" => ["1", "0", "1", "0%", "/dev"],
      "tmpfs" => ["1", "0", "1", "0%", "/sys/fs/cgroup"]
    }
  end
end
