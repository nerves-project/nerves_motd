# SPDX-FileCopyrightText: 2021 Frank Hunleth
# SPDX-FileCopyrightText: 2021 Masatoshi Nishiguchi
#
# SPDX-License-Identifier: Apache-2.0
#

# Choose tests depending on whether :nerves_time_zones is available
exclude =
  case Application.ensure_all_started(:nerves_time_zones) do
    {:ok, _} -> [no_nerves_time_zones: true]
    _ -> [has_nerves_time_zones: true]
  end

Mimic.copy(NervesMOTD.Model)

ExUnit.start(exclude: exclude)
