defmodule Mix.Tasks.Compile.TipCompiler do
  use Mix.Task

  @recursive true

  def run(_args) do
    File.ls!("tips")
    |> Enum.each(&process_file/1)
  end

  defp process_file(file) do
    priv_path = Path.join(Mix.Project.app_path(), "priv")
    File.mkdir_p!(priv_path)

    source_strings = File.read!("tips/#{file}")
    divider = "\n%\n"
    divider_byte_size = byte_size(divider)

    {indices, _} =
      source_strings
      |> String.split(divider)
      |> Enum.reduce({[], 0}, fn tip, {indices, current_location} ->
        how_many_bytes = byte_size(tip)
        next_location = current_location + how_many_bytes + divider_byte_size
        new_index = {current_location, how_many_bytes}

        {[new_index | indices], next_location}
      end)

    result = indices |> Enum.reverse() |> :erlang.term_to_binary()

    strings_file = Path.join(priv_path, file)
    index_file = Path.join(priv_path, "#{file}.index")
    File.write!(strings_file, source_strings)
    File.write!(index_file, result)
  end
end
