# Changelog

This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
