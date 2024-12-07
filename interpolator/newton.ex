defmodule Interpolator.Newton do
  @moduledoc """
  Newton interpolation implementation.
  Computes intermediate points based on given points using the Newton formula.
  """

  def interpolate(points, step_size) do
    # Ensure points are sorted by x before interpolation
    sorted_points = Enum.sort_by(points, &elem(&1, 0))

    # Extract minimum and maximum x values
    {min_x, max_x} = sorted_points |> Enum.map(&elem(&1, 0)) |> Enum.min_max()

    # Generate x values for interpolation
    generate_x_values(min_x, max_x, step_size)
    |> Enum.map(fn x -> {x, newton_value(sorted_points, x)} end)
  end

  defp newton_value(points, x) do
    # Compute the divided differences
    divided_differences = compute_divided_differences(points)

    # Construct the Newton polynomial
    Enum.reduce(Enum.with_index(divided_differences), 0, fn {diff, i}, acc ->
      acc + diff * newton_basis(points, i, x)
    end)
  end

  defp compute_divided_differences(points) do
    # Extract x and y values separately for processing
    xs = Enum.map(points, &elem(&1, 0))
    ys = Enum.map(points, &elem(&1, 1))

    # Start with the initial y values
    Enum.reduce(1..(length(points) - 1), [ys], fn _, acc ->
      prev_differences = hd(acc)

      # Calculate the next level of divided differences
      new_differences =
        prev_differences
        |> Enum.zip(Enum.drop(prev_differences, 1)) # Pair adjacent differences
        |> Enum.zip(xs)                            # Pair with corresponding x values
        |> Enum.zip(Enum.drop(xs, 1))              # Pair with next x values
        |> Enum.map(fn {{{y1, y2}, x1}, x2} -> (y2 - y1) / (x2 - x1) end)

      [new_differences | acc]
    end)
    |> Enum.reverse()
    |> Enum.map(&hd/1)
  end

  defp newton_basis(points, index, x) do
    Enum.take(points, index)
    |> Enum.reduce(1, fn {xi, _}, acc -> acc * (x - xi) end)
  end

  defp generate_x_values(start, stop, step) do
    Stream.iterate(start, &(&1 + step))
    |> Stream.take_while(&(&1 <= stop))
  end
end
