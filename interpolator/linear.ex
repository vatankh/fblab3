defmodule Interpolator.Linear do
  @moduledoc """
  Linear interpolation implementation.
  Computes intermediate points between two given points.
  """

  def interpolate(points, step_size) do
    # Ensure points are sorted by x before interpolation
    sorted_points = Enum.sort_by(points, &elem(&1, 0))

    case sorted_points do
      [{x1, y1}, {x2, y2}] when x1 < x2 ->
        Enum.reduce_while(generate_x_values(x1, x2, step_size), [], fn x, acc ->
          y = y1 + (x - x1) * (y2 - y1) / (x2 - x1)
          {:cont, acc ++ [{x, y}]}
        end)

      _ ->
        raise ArgumentError, "Linear interpolation requires exactly two distinct points with x1 < x2."
    end
  end

  defp generate_x_values(start, stop, step) do
    Stream.iterate(start, &(&1 + step))
    |> Stream.take_while(&(&1 <= stop))
  end
end
