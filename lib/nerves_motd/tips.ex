defmodule NervesMOTD.Tips do
  @moduledoc false

  alias NervesMOTD.Strfile

  @doc """
  Pick one tip randomly
  """
  @spec random() :: {:ok, String.t()} | {:error, atom()}
  def random() do
    path = tips_paths() |> Enum.random()

    with {:ok, strfile} <- Strfile.open(path),
         rand_index = :rand.uniform(strfile.header.num_string) - 1,
         {:ok, string} <- Strfile.read_string(strfile, rand_index) do
      _ = Strfile.close(strfile)
      {:ok, string}
    end
  end

  @doc """
  Raising version of random/0
  """
  def random!() do
    case random() do
      {:ok, string} -> string
      {:error, reason} -> raise RuntimeError, "Tips.random failed with #{reason}"
    end
  end

  @doc """
  Scan search paths for fortune files
  """
  @spec tips_paths() :: [String.t()]
  def tips_paths() do
    paths = [Application.app_dir(:nerves_motd, "priv"), "/opt/homebrew/share/games/fortunes/"]
    Strfile.search_paths(paths)
  end

  @spec tips_info(Path.t()) :: {:ok, map()} | {:error, atom()}
  def tips_info(path) do
    Strfile.read_info(path)
  end
end
