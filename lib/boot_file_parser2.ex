defmodule BootFileParser2 do
  @moduledoc """
  Parses the compiled .boot file to determine which applications are loaded and started.
  """

  @doc """
  Return all applications started by the release script
  """
  def parse_boot_file() do
    {:ok, [[boot]]} = :init.get_argument(:boot)
    contents = File.read!("#{boot}.boot")
    {:script, _name, instructions} = :erlang.binary_to_term(contents)

    {:ok, extract_started_apps(instructions)}
  rescue
    _ -> :error
  end

  defp extract_started_apps(instructions) do
    Enum.reduce(instructions, [], fn
      {:apply, {:application, :start_boot, [app | _]}}, acc -> [app | acc]
      _, acc -> acc
    end)
  end
end
