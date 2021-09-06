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
