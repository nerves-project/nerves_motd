defmodule NervesMOTD.Tips do
  @moduledoc false

  @tips [
    {
      "Toolshed",
      """
      Want more traditional shell tools in your Nerves IEx?

      Use Toolshed!

      Its included by default and has may familiar functions, such as `cat`,
      `ls`, or even `weather` 🌤️

      https://hexdocs.pm/toolshed
      """
    },
    {
      "Kernek log message",
      """
      Need more than Elixir logs? Run `dmesg` to see log messages from device
      drivers and the Linux kernel. Nerves also routes kernel log messages to
      the Elixir logger.
      """
    },
    {
      "erlinit",
      """
      Erlinit is a small program that starts the Erlang VM on boot. It has many
      options - especially for debugging startup issues.

      https://hexdocs.pm/nerves/advanced-configuration.html#overriding-erlinit-config-from-mix-config
      """
    },
    {
      "Disable automatic reboot",
      """
      Nerves automatically reboots devices when the Erlang VM exits. This can
      make some debugging harder, but you can easily disable it to let those
      sessions hang for debugging
      """
    },
    {
      "Whats in a firmware?",
      """
      Use `mix firmware.unpack` to decompress a local copy of your firmware on
      host and inspect the files within before installing on device
      """
    },
    {
      "Elixir Circuits libraries",
      """
      See if someone has already implemented support for a sensor or other
      hardware device that you have by checking
      https://elixir-circuits.github.io/.
      """
    },
    {
      "Read-only filesystems",
      """
      Nerves stores all BEAM files, the Erlang runtime and various support
      libraries/apps in a compressed and read-only SquashFS filesystem.

      Need to write to disk? Use the application partition mounted R/W at
      `/data`
      """
    },
    {
      "SASL log messages",
      """
      Configuring the Elixir Logger to show SASL reports can help debug
      unexpected GenServer restarts.

      https://hexdocs.pm/logger/Logger.html#module-erlang-otp-integration
      """
    },
    {
      "Viewing the file system",
      """
      Sometimes, you just need to see whats on your Nerves device's disk.
      Luckily, there are a few ways to do that. You can even use VSCode!

      https://embedded-elixir.com/post/2021-05-08-nerves-file-peeking/#sshfs
      """
    },
    {
      "NervesPack",
      """
      Get all of the default packages for starting a new Nerves project by
      depending on `:nerves_pack`

      https://github.com/nerves-project/nerves_pack
      """
    },
    {
      "Hardware watchdogs",
      """
      Nerves enables hardware watchdogs and connects them to Erlang's heart
      feature to detect and recover from the Erlang VM hanging.

      See https://embedded-elixir.com/post/2018-12-10-heart/ to learn more
      about this.
      """
    },
    {
      "Copy and paste",
      """
      Make small code changes to your running application by copy/pasting
      Elixir source files at the IEx prompt.
      """
    },
    {
      "Read-only filesystems",
      """
      Nerves stores all BEAM files, the Erlang runtime and various support
      libraries and apps in a compressed and read-only SquashFS filesystem.

      The writable application partition is mounted at `/data`
      """
    },
    {
      "Device serial numbers",
      """
      Identify your Nerves devices using a unique ID that's already programmed
      into the hardware using the boardid command. Details at
      https://github.com/nerves-project/boardid/ and the boardid.config file.
      """
    },
    {
      "Need an example?",
      """
      Nerves maintains a set of examples for common use-cases with devices.
      Things like running a phoenix app, using SQLite, controlling GPIO, using
      Zig lang, and more!

      https://github.com/nerves-project/nerves_examples
      """
    },
    {
      "Logs",
      """
      Use `RingLogger.next` to dump the current log buffer to screen.

      Use `log_attach` from `Toolshed` to attach the current session to the
      Elixir logger for live logs.

      https://hexdocs.pm/toolshed/Toolshed.Log.html#log_attach/1
      """
    },
    {
      "Eye from the Sky",
      """
      Get some insights to Nerves internals with this high level overview of
      the Nerves architecture and choice to use the BEAM VM

      https://youtu.be/VzOaSvTcvU4
      """
    },
    {
      "Revert to the previously loaded firmware",
      """
      Run `Nerves.Runtime.revert` to go back to the previously loaded firmware.
      """
    },
    {
      "Compiling systems",
      """
      Compiling systems on linux or via `mix nerves.system.shell`?

      Don't forgot about `make help` and other tips from the Buildroot manual
      (thanks @ericr3r)

      https://buildroot.org/downloads/manual/manual.html#make-tips
      """
    },
    {
      "Order matters",
      """
      Sometimes when compiling Nerves systems, order matters!

      Use `make show-build-order` while in `mix nerves.system.shell` to see the
      compilation order and make sure all your 🦆🦆 are in a row (thanks
      @ericr3r!)
      """
    },
    {
      "RamoopsLogger",
      """
      Use the `RamoopsLogger` backend to store log messages in DRAM that can
      survive unexpected reboots.

      https://github.com/smartrent/ramoops_logger
      """
    }
  ]

  @type tip :: {title :: String.t(), content :: String.t()}

  @doc """
  List all Nerves tips
  """
  @spec all() :: [tip]
  def all(), do: @tips

  @doc """
  Pick one Nerves tip randomly
  """
  @spec random() :: tip
  def random(), do: Enum.random(@tips)
end
