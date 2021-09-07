# Always warning as errors
if Version.match?(System.version(), "~> 1.10") do
  Code.put_compiler_option(:warnings_as_errors, true)
end

# Define dynamic mocks
Mox.defmock(NervesMOTD.MockRuntime, for: NervesMOTD.Runtime)

ExUnit.start()
