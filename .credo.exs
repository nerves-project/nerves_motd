# SPDX-FileCopyrightText: None
# SPDX-License-Identifier: CC0-1.0
%{
  configs: [
    %{
      name: "default",
      checks: [
        {Credo.Check.Readability.ParenthesesOnZeroArityDefs, parens: true}
      ]
    }
  ]
}
