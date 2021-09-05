defmodule NervesMOTD.Runtime do
  @moduledoc false
  @callback firmware_valid? :: boolean
  @callback load_average :: binary | nil
  @callback memory_usage :: [integer]
end

defmodule NervesMOTD.Runtime.Target do
  @moduledoc false
  @behaviour NervesMOTD.Runtime

  @impl NervesMOTD.Runtime
  def firmware_valid? do
    Nerves.Runtime.firmware_valid?()
  end

  @impl NervesMOTD.Runtime
  def load_average do
    case File.read("/proc/loadavg") do
      {:ok, data_str} -> String.trim(data_str)
      _ -> nil
    end
  end

  @impl NervesMOTD.Runtime
  def memory_usage do
    [_total, _used, _free, _shared, _buff, _available] =
      System.cmd("free", [])
      |> elem(0)
      |> String.split("\n")
      |> tl
      |> hd
      |> String.split()
      |> tl
      |> Enum.map(&String.to_integer/1)
  end
end
