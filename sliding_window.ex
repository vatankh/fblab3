defmodule SlidingWindow do
  @moduledoc """
  Maintains a dynamic-size sliding window of data points based on algorithm requirements.

  Supports adding points and accessing the current window.
  """

  defstruct size: 0, points: []

  @doc """
  Creates a new sliding window with a given size.
  """
  def new(size) when size > 0 do
    %SlidingWindow{size: size, points: []}
  end

  @doc """
  Adds a new point to the sliding window.
  If the window exceeds its size, the oldest point is removed.
  """
  def add_point(%SlidingWindow{size: size, points: points} = window, point) do
    new_points = points ++ [point]
    if length(new_points) > size do
      %SlidingWindow{window | points: tl(new_points)}
    else
      %SlidingWindow{window | points: new_points}
    end
  end

  @doc """
  Returns the current points in the sliding window.
  """
  def get_points(%SlidingWindow{points: points}) do
    points
  end

  @doc """
  Checks if the sliding window has enough points for a given algorithm.
  """
  def sufficient_points?(%SlidingWindow{points: points}, required_size) do
    length(points) >= required_size
  end
end
