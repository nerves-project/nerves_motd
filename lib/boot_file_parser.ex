defmodule BootFileParser do
  @moduledoc """
  Parses the compiled .boot file to determine which applications are loaded and started.
  """

  @doc """
  Returns a map with:
    - `:loaded_only()` — apps loaded but not started
    - `:started()` — apps started at boot
  """
  def parse_boot_file!() do
    path = find_boot_file_path!()
    instructions = read_boot_file!(path)
    extract_apps(instructions)
  end

  defp find_boot_file_path!() do
    case :init.get_argument(:boot) do
      {:ok, [[boot]]} ->
        path_abs = Path.absname("#{boot}.boot")

        if !File.exists?(path_abs) do
          raise "Boot file not found: #{path_abs}"
        end

        path_abs

      _ ->
        raise "Could not determine boot file path"
    end
  end

  defp read_boot_file!(path) do
    terms = File.read!(path) |> :erlang.binary_to_term()

    case terms do
      {:script, _name, instructions} -> instructions
      _ -> raise "Unexpected boot file format"
    end
  end

  defp extract_apps(instructions) do
    Enum.reduce(instructions, {MapSet.new(), MapSet.new()}, fn
      {:apply, {:application, :load, [{:application, app, _} | _]}}, {loaded, started} ->
        {MapSet.put(loaded, app), started}

      {:apply, {:application, :start_boot, [app | _]}}, {loaded, started} ->
        {loaded, MapSet.put(started, app)}

      x, acc ->
        dbg(x)
        acc
    end)
    |> then(fn {loaded, started} ->
      %{
        loaded_only: MapSet.difference(loaded, started) |> MapSet.to_list() |> Enum.sort(),
        started: MapSet.to_list(started) |> Enum.sort()
      }
    end)
  end
end
