defmodule NervesMOTD.Runtime do
  @moduledoc false
  @callback validate_firmware :: :ok | {:error, any}
end

defmodule NervesMOTD.Runtime.Prod do
  @moduledoc false
  @behaviour NervesMOTD.Runtime

  @impl NervesMOTD.Runtime
  def validate_firmware do
    Nerves.Runtime.validate_firmware()
  end
end

defmodule NervesMOTD.Runtime.Test do
  @moduledoc false
  @behaviour NervesMOTD.Runtime

  @impl NervesMOTD.Runtime
  def validate_firmware do
    :ok
  end
end
