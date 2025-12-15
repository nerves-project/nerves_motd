defmodule NervesMOTD.Info do
  @moduledoc """
  Struct for holding all of the information printed by `NervesMOTD.print/1`.
  """

  @typedoc """
  Criticality and details for a field

  This is the value type for the `:warnings` field in `NervesMOTD.Info.t()`. If
  there's an issue supplying one of the standard fields, an entry should be added
  to `:warnings` so that NervesMOTD can highlight the field and provide more information.
  """
  @type warning() :: {Logger.level(), String.t()}

  @typedoc """
  Information for generating the message of the day

  This struct gets passed to one or more information providers to gather system
  information. Providers should fill in fields they know. Fields that remain `nil`
  empty will either not be displayed or show up as unavailable.
  """
  @type t() :: %__MODULE__{
          serial_number: String.t() | nil,
          uptime_s: non_neg_integer() | nil,
          current_date_time: DateTime.t() | nil,
          cpu_temperature_c: float() | nil,
          firmware_validity: :valid | :invalid | nil,
          active_partition: String.t() | nil,
          otp_application_status: %{String.t() => :started | :loaded} | nil,
          dram_size_bytes: non_neg_integer() | nil,
          dram_used_bytes: non_neg_integer() | nil,
          data_partition_size_bytes: non_neg_integer() | nil,
          data_partition_used_bytes: non_neg_integer() | nil,
          hostname: String.t() | nil,
          load_averages: [float()] | nil,
          total_input_bytes: non_neg_integer() | nil,
          total_output_bytes: non_neg_integer() | nil,
          port_count: non_neg_integer() | nil,
          process_count: non_neg_integer() | nil,
          total_run_queue: non_neg_integer() | nil,
          cpu_run_queue: non_neg_integer() | nil,
          ip_addresses: [{String.t(), [:inet.ip_address()]}],
          warnings: %{atom() => warning()},
          extra_rows: [%{key: IO.ANSI.ansidata(), value: IO.ANSI.ansidata()}]
        }
  defstruct serial_number: nil,
            uptime_s: nil,
            current_date_time: nil,
            cpu_temperature_c: nil,
            firmware_validity: nil,
            active_partition: nil,
            otp_application_status: nil,
            dram_size_bytes: nil,
            dram_used_bytes: nil,
            data_partition_size_bytes: nil,
            data_partition_used_bytes: nil,
            hostname: nil,
            load_averages: nil,
            total_input_bytes: nil,
            total_output_bytes: nil,
            port_count: nil,
            process_count: nil,
            total_run_queue: nil,
            cpu_run_queue: nil,
            ip_addresses: [],
            warnings: %{},
            extra_rows: []
end
