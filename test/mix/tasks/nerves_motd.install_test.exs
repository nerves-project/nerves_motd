# SPDX-FileCopyrightText: 2025 Frank Hunleth
# SPDX-FileCopyrightText: 2025 Peter Ullrich
# SPDX-FileCopyrightText: 2026 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Mix.Tasks.NervesMotd.InstallTest do
  @moduledoc false
  use ExUnit.Case, async: true

  import Igniter.Test

  @iex_exs "rootfs_overlay/etc/iex.exs"
  @target_exs %{"config/target.exs" => "import Config\n"}

  defp nerves_project(files \\ %{}) do
    test_project(files: Map.merge(@target_exs, files))
  end

  defp install(igniter, argv \\ []) do
    Igniter.compose_task(igniter, "nerves_motd.install", argv)
  end

  defp content(igniter, path) do
    igniter.rewrite |> Rewrite.source!(path) |> Rewrite.Source.get(:content)
  end

  defp count_prints(igniter, path) do
    igniter |> content(path) |> String.split("NervesMOTD.print") |> length() |> Kernel.-(1)
  end

  describe "install" do
    test "creates the iex.exs if it does not exist at the default filepath" do
      igniter = nerves_project() |> install()

      assert_creates(igniter, @iex_exs, "NervesMOTD.print()\n")
      assert igniter.notices == []
    end

    test "detects a Nerves project by its :nerves dependency" do
      igniter =
        test_project()
        |> Igniter.Project.Deps.add_dep({:nerves, "~> 1.10", runtime: false})
        |> install()

      assert_creates(igniter, @iex_exs, "NervesMOTD.print()\n")
      assert igniter.notices == []
    end

    test "adds the print statement to an existing iex.exs file" do
      test_project(files: %{"rootfs_overlay/etc/iex.exs" => ""})
      |> Igniter.compose_task("nerves_motd.install", [])
      |> assert_has_patch("rootfs_overlay/etc/iex.exs", """
      |NervesMOTD.print()
      |
      """)
    end

    test "adds the print statement to an iex.exs file at a provided filepath" do
      test_project(files: %{"somewhere/iex.exs" => ""})
      |> Igniter.compose_task("nerves_motd.install", ["--file", "somewhere/iex.exs"])
      |> assert_has_patch("somewhere/iex.exs", """
      |NervesMOTD.print()
      |
      """)
    end

    test "creates the iex.exs file at a provided filepath" do
      igniter = nerves_project() |> install(["-f", "overlays/etc/iex.exs"])

      assert_creates(igniter, "overlays/etc/iex.exs", "NervesMOTD.print()\n")
      refute Igniter.exists?(igniter, @iex_exs)
    end

    test "appends to an existing iex.exs and preserves its content" do
      igniter =
        nerves_project(%{
          @iex_exs => """
          # My helpers
          import MyApp.Helpers
          """
        })
        |> install()

      assert content(igniter, @iex_exs) == """
             # My helpers
             import MyApp.Helpers

             NervesMOTD.print()
             """
    end

    test "is a no-op when NervesMOTD.print is already called with options" do
      nerves_project(%{@iex_exs => "NervesMOTD.print(logo: \"\")\n"})
      |> install()
      |> assert_unchanged(@iex_exs)
    end

    test "is a no-op when NervesMOTD.print is called in a nested expression" do
      nerves_project(%{
        @iex_exs => """
        if Code.ensure_loaded?(NervesMOTD) do
          NervesMOTD.print()
        end
        """
      })
      |> install()
      |> assert_unchanged(@iex_exs)
    end

    test "a commented out NervesMOTD.print() doesn't count" do
      igniter = nerves_project(%{@iex_exs => "# NervesMOTD.print()\n"}) |> install()

      assert content(igniter, @iex_exs) == """
             # NervesMOTD.print()

             NervesMOTD.print()
             """
    end

    test "is idempotent" do
      nerves_project()
      |> install()
      |> apply_igniter!()
      |> install()
      |> assert_unchanged()
    end

    test "is idempotent on an existing file" do
      igniter =
        nerves_project(%{@iex_exs => "import MyApp.Helpers\n"})
        |> install()
        |> apply_igniter!()
        |> install()

      assert_unchanged(igniter)
      assert count_prints(igniter, @iex_exs) == 1
    end

    test "is idempotent when composed twice without applying" do
      igniter = nerves_project() |> install() |> install()

      assert count_prints(igniter, @iex_exs) == 1
    end
  end

  describe "non-Nerves project" do
    test "creates the iex.exs and adds a notice" do
      igniter = test_project() |> install()

      assert_creates(igniter, @iex_exs, "NervesMOTD.print()\n")
      assert_has_notice(igniter, &(&1 =~ "doesn't look like a Nerves project"))
    end

    test "is idempotent and quiet the second time" do
      igniter = test_project() |> install() |> apply_igniter!() |> install()

      assert_unchanged(igniter)
      assert igniter.notices == []
    end
  end

  describe "coexisting with toolshed.install" do
    # toolshed's installer edits the same file. It isn't a dependency here, so
    # this mirrors what it does: append its snippet to the file's text unless
    # `use Toolshed` is already there, creating the file if missing.
    @toolshed_snippet """
    # Add Toolshed helpers to the IEx session
    use Toolshed
    """

    defp install_toolshed(igniter) do
      Igniter.create_or_update_file(igniter, @iex_exs, @toolshed_snippet, fn source ->
        content = Rewrite.Source.get(source, :content)

        if content =~ ~r/^\s*use\s+Toolshed\b/m do
          source
        else
          appended = String.trim_trailing(content) <> "\n\n" <> @toolshed_snippet
          Rewrite.Source.update(source, :content, appended)
        end
      end)
    end

    defp count_uses(igniter) do
      igniter |> content(@iex_exs) |> String.split("\nuse Toolshed") |> length() |> Kernel.-(1)
    end

    test "is a no-op on the mix nerves.new iex.exs" do
      nerves_project(%{
        @iex_exs => """
        NervesMOTD.print()

        # Add Toolshed helpers to the IEx session
        use Toolshed
        """
      })
      |> install()
      |> install_toolshed()
      |> assert_unchanged(@iex_exs)
    end

    test "adds a separate expression to a file that only has use Toolshed" do
      igniter = nerves_project(%{@iex_exs => "use Toolshed\n"}) |> install()

      assert content(igniter, @iex_exs) == """
             use Toolshed

             NervesMOTD.print()
             """
    end

    test "toolshed first, then nerves_motd" do
      igniter =
        nerves_project()
        |> install_toolshed()
        |> apply_igniter!()
        |> install()

      assert content(igniter, @iex_exs) == """
             # Add Toolshed helpers to the IEx session
             use Toolshed

             NervesMOTD.print()
             """

      igniter
      |> apply_igniter!()
      |> install_toolshed()
      |> install()
      |> assert_unchanged()
    end

    test "nerves_motd first, then toolshed" do
      igniter =
        nerves_project()
        |> install()
        |> apply_igniter!()
        |> install_toolshed()

      assert content(igniter, @iex_exs) == """
             NervesMOTD.print()

             # Add Toolshed helpers to the IEx session
             use Toolshed
             """

      igniter
      |> apply_igniter!()
      |> install()
      |> install_toolshed()
      |> assert_unchanged()
    end

    test "both in the same run" do
      igniter =
        nerves_project() |> install() |> install_toolshed() |> install() |> install_toolshed()

      assert count_prints(igniter, @iex_exs) == 1
      assert count_uses(igniter) == 1
    end
  end
end
