defmodule NervesMOTD.Tips do
  @moduledoc false

  # Returns a tuple list of location and byte size of each tip entry in the provided file.
  index_file = fn filename, divider when is_binary(filename) and is_binary(divider) ->
    divider_byte_size = byte_size(divider)

    {indices, _} =
      File.read!(filename)
      |> String.trim()
      |> String.split(divider, trim: true)
      |> Enum.reduce({[], 0}, fn tip, {indices, current_location} ->
        how_many_bytes = byte_size(tip)
        next_location = current_location + how_many_bytes + divider_byte_size
        new_index = {current_location, how_many_bytes}

        {[new_index | indices], next_location}
      end)

    indices
  end

  @default_tips_file "priv/default_tips.txt"
  @divider "%%%"
  @indices Application.app_dir(:nerves_motd, [@default_tips_file]) |> index_file.(@divider)

  def indices, do: @indices

  @doc """
  Pick one tip randomly
  """
  @spec random() :: {:ok, String.t()} | {:error, any}
  def random() do
    {location, how_many_bytes} = Enum.random(@indices)
    read_file_at_location(tips_file(), location, how_many_bytes)
  end

  defp tips_file do
    # this is different from the one at compile time
    Application.app_dir(:nerves_motd, [@default_tips_file])
  end

  defp read_file_at_location(filename, location, how_many_bytes) do
    with {:ok, io_device} <- File.open(filename, [:read]),
         {:ok, data} <- :file.pread(io_device, location, how_many_bytes),
         :ok <- File.close(io_device),
         do: {:ok, String.trim(data)}
  end
end
