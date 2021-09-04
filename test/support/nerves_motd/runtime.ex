defmodule NervesMOTD.Runtime.Test do
  @moduledoc false
  @behaviour NervesMOTD.Runtime

  @impl NervesMOTD.Runtime
  def firmware_valid?, do: true
end
