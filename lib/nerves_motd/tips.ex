defmodule NervesMOTD.Tips do
  @moduledoc false

  @divider "\n\n"
  @default_tips File.read!("config/default_tips.txt")
                |> String.split(@divider, trim: true)
                |> Enum.reject(&(&1 == ""))

  @type tip :: String.t()

  @doc """
  List all tips
  """
  @spec all(keyword) :: [tip]
  def all(opts \\ []) do
    extra_tips = Keyword.get(opts, :extra_tips, [])
    @default_tips ++ extra_tips
  end

  @doc """
  Pick one tip randomly
  """
  @spec random(keyword) :: tip
  def random(opts \\ []) do
    all(opts)
    |> Enum.reject(&(&1 == ""))
    |> Enum.random()
  end
end
