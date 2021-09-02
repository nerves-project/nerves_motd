defmodule NervesMOTD.Linux do
  @moduledoc false
  @callback load_average :: binary | nil
  @callback memory_usage :: [integer]
end

defmodule NervesMOTD.Linux.Prod do
  @moduledoc false
  @behaviour NervesMOTD.Linux

  @impl NervesMOTD.Linux
  def load_average do
    case File.read("/proc/loadavg") do
      {:ok, data_str} -> String.trim(data_str)
      _ -> nil
    end
  end

  @impl NervesMOTD.Linux
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

defmodule NervesMOTD.Linux.Test do
  @moduledoc false
  @behaviour NervesMOTD.Linux

  @impl NervesMOTD.Linux
  def load_average do
    "0.35 0.16 0.11 2/70 1536"
  end

  @impl NervesMOTD.Linux
  def memory_usage do
    [316_664, 78_408, 126_776, 12, 111_480, 238_564]
  end
end
