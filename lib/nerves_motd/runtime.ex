defmodule NervesMotd.Runtime do
  @moduledoc false
  @callback validate_firmware :: :ok | {:error, any}
end

defmodule NervesMotd.Runtime.Prod do
  @moduledoc false
  @behaviour NervesMotd.Runtime

  @impl NervesMotd.Runtime
  def validate_firmware do
    Nerves.Runtime.validate_firmware()
  end
end

defmodule NervesMotd.Runtime.Test do
  @moduledoc false
  @behaviour NervesMotd.Runtime

  @impl NervesMotd.Runtime
  def validate_firmware do
    :ok
  end
end
