defmodule BootFileParser2 do
  @moduledoc """
  Parses the compiled .boot file to determine which applications are loaded and started.
  """

  @doc """
  Return all applications started by the release script
  """
  @spec parse_boot_file() :: {:ok, [atom()]} | :error
  def parse_boot_file() do
    {:ok, [[boot]]} = :init.get_argument(:boot)
    contents = File.read!("#{boot}.boot")
    {:script, _name, instructions} = :erlang.binary_to_term(contents)

    apps = for {:apply, {:application, :start_boot, [app | _]}} <- instructions, do: app
    {:ok, apps}
  rescue
    _ -> :error
  end
end
