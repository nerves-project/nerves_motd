defmodule Mix.Tasks.Compile.TipCompiler do
  use Mix.Task

  @strfile_version 2
  @strfile_separator ?%

  @recursive true

  def run(_args) do
    File.ls!("tips")
    |> Enum.each(&process_file/1)
  end

  defstruct location: 0, num_string: 0, shortest_string: 4096, longest_string: 0, indices: []

  defp process_file(file) do
    priv_path = Path.join(Mix.Project.app_path(), "priv")
    File.mkdir_p!(priv_path)

    source_strings = File.read!("tips/#{file}")
    divider = <<?\n, @strfile_separator, ?\n>>

    state = %__MODULE__{}

    state =
      source_strings
      |> String.split(divider)
      |> process_strings(state)

    strings_file = Path.join(priv_path, file)
    index_file = Path.join(priv_path, "#{file}.dat")

    File.write!(strings_file, source_strings)
    File.write!(index_file, [strfile_header(state), indices_to_binary(state.indices)])
  end

  defp process_strings([], state) do
    %{state | indices: Enum.reverse(state.indices)}
  end

  defp process_strings(["" | rest], state) do
    process_strings(rest, state)
  end

  defp process_strings([string | rest], state) do
    location = state.location
    len = byte_size(string)
    next_location = location + len + 3

    next_state = %{
      indices: [location | state.indices],
      location: next_location,
      num_string: state.num_string + 1,
      shortest_string: min(state.shortest_string, len),
      longest_string: max(state.longest_string, len)
    }

    process_strings(rest, next_state)
  end

  defp indices_to_binary(indices) do
    for i <- indices, do: <<i::32>>
  end

  defp strfile_header(state) do
    rotated? = 0
    ordered? = 0
    random? = 0

    <<@strfile_version::32, state.num_string::32, state.longest_string::32,
      state.shortest_string::32, 0::29, rotated?::1, ordered?::1, random?::1,
      @strfile_separator::8, 0::24>>
  end
end
