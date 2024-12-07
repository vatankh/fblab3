defmodule InputParser do
  @moduledoc """
  Reads and parses input data from stdin. Converts raw CSV-like lines into {x, y} tuples and ensures sorting.
  """

  def stream_input(delimiter \\ ",") do
    IO.stream(:stdio, :line)
    |> Stream.map(&String.trim/1) # Remove trailing whitespace
    |> Stream.reject(&(&1 == "")) # Ignore empty lines
    |> Stream.map(fn line ->
      parse_line(line, delimiter)
    end)
    |> Enum.sort_by(&elem(&1, 0)) # Ensure sorting by x
  end


  defp parse_line(line, delimiter) do
    case String.split(line, delimiter) do
      [x_str, y_str] ->
        case {parse_number(x_str), parse_number(y_str)} do
          {x, y} when is_number(x) and is_number(y) ->
            {x, y}
          _ ->
            raise ArgumentError, "Invalid line: #{line}. Expected format: x#{delimiter}y."
        end

      _ ->
        raise ArgumentError, "Invalid line: #{line}. Expected format: x#{delimiter}y."
    end
  end

  defp parse_number(value) do
    case Float.parse(value) do
      {num, ""} -> num
      _ -> nil
    end
  end

end
