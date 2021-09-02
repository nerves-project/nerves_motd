# Always warning as errors
if Version.match?(System.version(), "~> 1.10") do
  Code.put_compiler_option(:warnings_as_errors, true)
end

# Define dynamic mocks
Mox.defmock(NervesMotd.MockRuntime, for: NervesMotd.Runtime)
Mox.defmock(NervesMotd.MockRuntimeKV, for: NervesMotd.RuntimeKV)
Mox.defmock(NervesMotd.MockLinux, for: NervesMotd.Linux)

# Override the config settings
Application.put_env(:nerves_motd, :runtime_mod, NervesMotd.MockRuntime)
Application.put_env(:nerves_motd, :runtime_kv_mod, NervesMotd.MockRuntimeKV)
Application.put_env(:nerves_motd, :linux_mod, NervesMotd.MockLinux)

ExUnit.start()
