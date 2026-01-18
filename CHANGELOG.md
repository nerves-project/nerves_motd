<!--
  SPDX-FileCopyrightText: None
  SPDX-License-Identifier: CC0-1.0
-->

# Changelog

This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v0.1.17 - 2026-01-18

* Improvements
  * Add firmware nickname to top line describing the firmware version. This
    makes it easier to check when the firmware UUID changes. Support is ongoing
    other places in Nerves to make the nickname more visible.

  * Use `Nerves.firmware_slots/0` to determine the active firmware slot to
    support firmware slot changes that aren't represented in the KV. This is for
    Raspberry Pi tryboot support.

* Bug fixes
  * Fix cases where `nil`s returned when porting Nerves could crash the MOTD
    print out.

## v0.1.16 - 2025-12-20

This release requires Elixir 1.14 or later.

* Fixes
  * Fix started application field to not warn on applications that are
    intentionally not started in the release.

* Improvements
  * Copyright and licensing has been updated to follow the REUSE standard
  * Support installation using Igniter. While this isn't necessary currently
    since `nerves_motd` is installed via `mix nerves.new`, in the future when
    more Nerves libraries support Igniter, the plan is to trim `nerves.new`.

## v0.1.15 - 2024-07-19

This release requires Elixir 1.13 or later. Previous versions became hard to
maintain due to dependent packages. No code changed in this library to prevent
previous versions from working.

* Fixes
  * Fix a regression that caused the firmware validity to always show up as valid even when invalid.

## v0.1.14 - 2024-06-02

* Improvements
  * Fix Elixir 1.17 warnings

## v0.1.13 - 2023-05-17

* Improvements
  * Support `:extra_rows` as a callback (#124)

## v0.1.12 - 2023-05-10

* Improvements
  * Use application environment for default options (#122)
  * Use yellow text color for clock and show unsyncronized help text when clock is out of sync (#74)

## v0.1.11 - 2023-02-04

* Bug fixes
  * Don't raise if `Nerves.Runtime.KV` is empty

* Improvements
  * Test with ANSI off to make tests easier to read
  * Update specs to `IO.chardata()` for consistency

## v0.1.10 - 2023-02-01

* Improvements
  * Print milliseconds when uptime < 60s
  * Add serial number

## v0.1.9 - 2022-11-17

* Improvements
  * Append `"°C"` to temperature value

## v0.1.8 - 2022-10-26

* Improvements
  * Show CPU temperature on MOTD
  * Support OTP 25
  * Update the Nerves CLI help url
  * Fix tests with nerves_runtime >= 0.11.9

## v0.1.7 - 2022-03-03

* Improvements
  * Skip printing MOTD if Nerves.Runtime isn't started. The previous behavior
    was to try to start Nerves.Runtime. The scenario this mostly affects is
    printing the MOTD to the serial console right after Elixir loads, but before
    Nerves.Runtime and the rest. Besides printing a slightly confusing MOTD of a
    partially started system, it also could reorder OTP application from the
    boot script.

## v0.1.6 - 2021-11-29

* Improvements
  * Add `:extra_rows` option to allow users to supply additional information to
    be printed in the MOTD. The use case for this is to show project-specific
    information like MQTT connection status in addition to the generic info.

## v0.1.5 - 2021-11-02

* Improvements
  * Print local time when a time zone has been set with `NervesTimeZones`
  * Handle exceptions from `NervesMOTD.print/1` so they don't prematurely end
    `iex.exs` scripts
  * Handle Nerves configurations that do not have an application data partition
  * Simplify text handling internally by using Elixir's `ansidata` throughout

## v0.1.4 - 2021-10-17

* Improvements
  * Improve the logo so that it can render properly on touchscreen

## v0.1.3 - 2021-10-10

* Improvements
  * Remove denominator (loaded application count) from the applications section because it is changeable and can cause confusion
  * Change text color for applications not (yet) loaded from red to yellow because most of the time it is transient

## v0.1.2 - 2021-09-25

* Improvements
  * Show IP addresses assigned to network interfaces

## v0.1.1 - 2021-09-15

* Updates
  * Refactor the template using `iodata`
  * Use round instead of trunc for percentage
  * Update screenshot in readme

## v0.1.0 - 2021-09-08

Initial release
