# SPDX-FileCopyrightText: 2025 Frank Hunleth
# SPDX-FileCopyrightText: 2025 Peter Ullrich
# SPDX-FileCopyrightText: 2026 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Mix.Tasks.NervesMotd.Install.Docs do
  @moduledoc false

  def short_doc() do
    "Installs nerves_motd in your Nerves project."
  end

  def example() do
    "mix igniter.install nerves_motd"
  end

  def long_doc() do
    """
    #{short_doc()}

    ## Example

    ```bash
    #{example()}
    ```

    ## Options

    * `--file` or `-f` - Optional path to the `iex.exs` file in your Nerves project. Defaults to: `rootfs_overlay/etc/iex.exs`

    The file is created if it doesn't exist. If it already calls
    `NervesMOTD.print/1`, nothing is changed.
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.NervesMotd.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"

    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    @snippet "NervesMOTD.print()\n"

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        # Groups allow for overlapping arguments for tasks by the same author
        # See the generators guide for more.
        group: :nerves_motd,
        # *other* dependencies to add
        # i.e `{:foo, "~> 2.0"}`
        adds_deps: [],
        # *other* dependencies to add and call their associated installers, if they exist
        # i.e `{:foo, "~> 2.0"}`
        installs: [],
        # An example invocation
        example: __MODULE__.Docs.example(),
        # A list of environments that this should be installed in.
        only: nil,
        # a list of positional arguments, i.e `[:file]`
        positional: [],
        # Other tasks your task composes using `Igniter.compose_task`, passing in the CLI argv
        # This ensures your option schema includes options from nested tasks
        composes: [],
        # `OptionParser` schema
        schema: [
          file: :string
        ],
        # Default values for the options in the `schema`
        defaults: [
          file: "rootfs_overlay/etc/iex.exs"
        ],
        # CLI aliases
        aliases: [
          f: :file
        ],
        # A list of options in the schema that are required
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      iex_path = igniter.args.options[:file]
      creating? = not Igniter.exists?(igniter, iex_path)

      igniter
      |> Igniter.create_or_update_file(iex_path, @snippet, fn source ->
        content = Rewrite.Source.get(source, :content)

        if prints_motd?(content) do
          source
        else
          Rewrite.Source.update(source, :content, append_snippet(content))
        end
      end)
      |> maybe_add_notice(iex_path, creating? and not nerves_project?(igniter))
    end

    defp maybe_add_notice(igniter, _path, false), do: igniter

    defp maybe_add_notice(igniter, path, true) do
      Igniter.add_notice(igniter, """
      NervesMOTD: this doesn't look like a Nerves project, so #{path} was
      created. The message of the day is only shown when that file is in the
      firmware's root filesystem overlay and loaded by IEx on the device.
      """)
    end

    defp nerves_project?(igniter) do
      Igniter.exists?(igniter, "config/target.exs") or
        Igniter.Project.Deps.has_dep?(igniter, :nerves)
    end

    # True if the file already calls `NervesMOTD.print/0,1` anywhere. Calls
    # with options count since they're a user's customization of the same line.
    defp prints_motd?(content) do
      case Sourceror.parse_string(content) do
        {:ok, ast} ->
          {_ast, found?} =
            Macro.prewalk(ast, false, fn
              {{:., _, [{:__aliases__, _, [:NervesMOTD]}, :print]}, _, _} = node, _acc ->
                {node, true}

              node, acc ->
                {node, acc}
            end)

          found?

        {:error, _} ->
          # Unparseable file: fall back to looking for an uncommented call
          Regex.match?(~r/^[^#\n]*\bNervesMOTD\.print\b/m, content)
      end
    end

    defp append_snippet(content) do
      case String.trim_trailing(content) do
        "" -> @snippet
        trimmed -> trimmed <> "\n\n" <> @snippet
      end
    end
  end
else
  defmodule Mix.Tasks.NervesMotd.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'nerves_motd.install' requires igniter. Please install igniter and try again.

      For more information, see: https://igniter.hexdocs.pm/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
