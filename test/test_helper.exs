# Always warning as errors
if Version.match?(System.version(), "~> 1.10") do
  Code.put_compiler_option(:warnings_as_errors, true)
end

# Choose tests depending on whether :nerves_time_zones is available
exclude =
  case Application.ensure_all_started(:nerves_time_zones) do
    {:ok, _} -> [no_nerves_time_zones: true]
    _ -> [has_nerves_time_zones: true]
  end

# Define dynamic mocks
Mox.defmock(NervesMOTD.MockRuntime, for: NervesMOTD.Runtime)

ExUnit.start(exclude: exclude)
