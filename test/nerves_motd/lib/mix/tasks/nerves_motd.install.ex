# SPDX-FileCopyrightText: 2025 Peter Ullrich
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Mix.Tasks.NervesMotd.InstallTest do
  @moduledoc false
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "install" do
    test "returns an error if the iex.exs does not exist at the default filepath" do
      assert {:error, [warning]} =
               test_project()
               |> Igniter.compose_task("nerves_motd.install", [])
               |> apply_igniter()

      assert warning =~ "Required rootfs_overlay/etc/iex.exs but it did not exist"
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
  end
end
