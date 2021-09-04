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
