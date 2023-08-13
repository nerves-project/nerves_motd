defmodule NervesMOTD.Tips do
  @moduledoc false

  @doc """
  Pick one tip randomly
  """
  @spec random() :: {:ok, String.t()} | {:error, any}
  def random() do
    path = tips_paths() |> Enum.random()

    {offset, len} = load_index(path) |> Enum.random()

    pread(path, offset, len)
  end

  def tips_paths() do
    priv_path = Application.app_dir(:nerves_motd, "priv")

    case File.ls(priv_path) do
      {:ok, paths} ->
        paths
        |> Enum.map(&Path.join(priv_path, &1))
        |> Enum.filter(&tips_path?/1)

      _error ->
        []
    end
  end

  def tips_path?(path) do
    Path.extname(path) == "" and
      File.exists?([path, ".index"])
  end

  def load_index(path) do
    index_path = [path, ".index"]
    File.read!(index_path) |> :erlang.binary_to_term([:safe])
  end

  def read_tip(path, index, tip_number) do
    {offset, len} = Enum.at(index, tip_number)
    pread(path, offset, len)
  end

  defp pread(path, offset, len) do
    with {:ok, io_device} <- File.open(path, [:read]),
         {:ok, data} <- :file.pread(io_device, offset, len),
         :ok <- File.close(io_device),
         do: {:ok, data}
  end
end
