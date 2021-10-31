import Config

config :nerves_runtime,
  target: "host",
  modules: %{Nerves.Runtime.KV => Nerves.Runtime.KV.Mock}

config :nerves_runtime, Nerves.Runtime.KV.Mock, %{
  "a.nerves_fw_application_part0_devpath" => "/dev/mmcblk0p3",
  "a.nerves_fw_application_part0_fstype" => "f2fs",
  "a.nerves_fw_application_part0_target" => "/root",
  "a.nerves_fw_architecture" => "arm",
  "a.nerves_fw_author" => "Nerves Project Authors",
  "a.nerves_fw_description" => "Unit test config",
  "a.nerves_fw_misc" => "",
  "a.nerves_fw_platform" => "rpi4",
  "a.nerves_fw_product" => "nerves_livebook",
  "a.nerves_fw_uuid" => "0540f0cd-f95a-5596-d152-221a70c078a9",
  "a.nerves_fw_vcs_identifier" => "",
  "a.nerves_fw_version" => "0.2.17",
  "nerves_fw_active" => "a",
  "nerves_fw_devpath" => "/dev/mmcblk0",
  "nerves_fw_validated" => "1",
  "nerves_serial_number" => ""
}

config :nerves_motd, runtime_mod: NervesMOTD.MockRuntime

if Mix.env() == :test do
  config :nerves_time_zones, default_time_zone: "Asia/Tokyo"
end
