defmodule CLI do
  @moduledoc """
  Command-line interface for the interpolation application.
  Parses and validates arguments, and returns configurations for the main application.
  """
  def parse_args(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        switches: [
          algorithms: :string,
          frequency: :float,
          delimiter: :string,
          mode: :string
        ],
        aliases: [
          a: :algorithms,
          f: :frequency,
          d: :delimiter,
          m: :mode
        ]
      )

    validate_args(opts)
  end
  defp validate_args(opts) do
    algorithms = Keyword.get(opts, :algorithms, "linear") |> String.split(",")
    frequency = Keyword.get(opts, :frequency, 1.0)
    delimiter = Keyword.get(opts, :delimiter, ",")
    mode = Keyword.get(opts, :mode, "csv") |> String.downcase()

    #  validation for mode if csv or interactive
    if mode != "csv" && mode != "interactive" do
      raise ArgumentError, "Unsupported mode: #{mode}. Supported: csv, interactive."
    end





    # Validation for algorithm types
    unless Enum.all?(algorithms, &(&1 in ["linear", "lagrange" ,"newton"])) do
      raise ArgumentError, "Unsupported algorithms: #{Enum.join(algorithms, ", ")}. Supported: linear, lagrange ,newton."
    end

    unless frequency > 0 do
      raise ArgumentError, "Frequency must be a positive number."
    end

    %{algorithms: algorithms, frequency: frequency, delimiter: delimiter,mode: mode}
  end
end
