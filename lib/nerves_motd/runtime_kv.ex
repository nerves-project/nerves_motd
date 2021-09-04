defmodule NervesMOTD.RuntimeKV do
  @moduledoc false
  @callback get(binary) :: any
  @callback get_active(binary) :: any
end

defmodule NervesMOTD.RuntimeKV.Prod do
  @moduledoc false
  @behaviour NervesMOTD.RuntimeKV

  @impl NervesMOTD.RuntimeKV
  def get(key) do
    Nerves.Runtime.KV.get(key)
  end

  @impl NervesMOTD.RuntimeKV
  def get_active(key) do
    Nerves.Runtime.KV.get_active(key)
  end
end
