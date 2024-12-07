defmodule Interpolator.Lagrange do
  @moduledoc """
  Lagrange interpolation implementation.
  Computes intermediate points based on given points using the Lagrange formula.
  """

  def interpolate(points, step_size) do
    # Extract minimum and maximum x values
    {min_x, max_x} = points |> Enum.map(&elem(&1, 0)) |> Enum.min_max()

    # Generate x values for interpolation
    generate_x_values(min_x, max_x, step_size)
    |> Enum.map(fn x -> {x, lagrange_value(points, x)} end)
  end

  defp lagrange_value(points, x) do
    Enum.reduce(points, 0, fn {xi, yi}, acc ->
      acc + yi * lagrange_basis(points, xi, x)
    end)
  end

  defp lagrange_basis(points, xi, x) do
    Enum.reduce(points, 1, fn {xj, _}, acc ->
      if xi != xj do
        acc * (x - xj) / (xi - xj)
      else
        acc
      end
    end)
  end

  defp generate_x_values(start, stop, step) do
    Stream.iterate(start, &(&1 + step))
    |> Stream.take_while(&(&1 <= stop))
  end
end
