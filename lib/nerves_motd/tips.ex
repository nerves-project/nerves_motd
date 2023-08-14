defmodule NervesMOTD.Tips do
  @moduledoc false

  alias NervesMOTD.Strfile

  @doc """
  Pick one tip randomly
  """
  @spec random() :: {:ok, String.t()} | {:error, any}
  def random() do
    path = tips_paths() |> Enum.random()

    with {:ok, strfile} <- Strfile.open(path),
         rand_index = :rand.uniform(strfile.header.num_string) - 1 do
      string = Strfile.read_string(strfile, rand_index)
      Strfile.close(strfile)
      string
    end
  end

  def tips_paths() do
    paths = [Application.app_dir(:nerves_motd, "priv"), "/opt/homebrew/share/games/fortunes/"]
    Strfile.search_paths(paths)
  end

  def tips_info(path) do
    Strfile.read_info(path)
  end
end
