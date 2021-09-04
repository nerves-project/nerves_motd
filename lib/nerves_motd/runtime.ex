defmodule NervesMOTD.Runtime do
  @moduledoc false
  @callback firmware_valid? :: boolean
end

defmodule NervesMOTD.Runtime.Prod do
  @moduledoc false
  @behaviour NervesMOTD.Runtime

  @impl NervesMOTD.Runtime
  def firmware_valid? do
    Nerves.Runtime.firmware_valid?()
  end
end
