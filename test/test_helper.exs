# Always warning as errors
if Version.match?(System.version(), "~> 1.10") do
  Code.put_compiler_option(:warnings_as_errors, true)
end

# Define dynamic mocks
Mox.defmock(NervesMOTD.MockRuntime, for: NervesMOTD.Runtime)
Mox.defmock(NervesMOTD.MockLinux, for: NervesMOTD.Linux)

# Override the config settings
Application.put_env(:nerves_motd, :runtime_mod, NervesMOTD.MockRuntime)
Application.put_env(:nerves_motd, :linux_mod, NervesMOTD.MockLinux)

ExUnit.start()
