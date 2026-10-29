# SPDX-FileCopyrightText: 2025 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesMOTD.ModelTest do
  use ExUnit.Case

  alias NervesMOTD.Model

  test "format_uuid/1" do
    # These all came from fwup unit tests
    assert "present-snack (b3c560af-d052-58c1-228d-5fa869817cda)" ==
             Model.format_uuid("b3c560af-d052-58c1-228d-5fa869817cda")

    assert "energy-bid (53233641-82a4-5576-b75d-d227a234c626)" ==
             Model.format_uuid("53233641-82a4-5576-b75d-d227a234c626")

    assert "visa-present (ecb37e6e-6a7b-5f22-2077-7ccad0e40d85)" ==
             Model.format_uuid("ecb37e6e-6a7b-5f22-2077-7ccad0e40d85")
  end
end
