defmodule InterpolationLab do
  @moduledoc """
  Main entry point for the interpolation application.
  """

  alias SlidingWindow
  alias Interpolator.Linear
  alias Interpolator.Lagrange
  alias Interpolator.Newton

  def main(args) do
    config = CLI.parse_args(args)

    IO.puts("Starting interpolation with configuration:")
    IO.inspect(config)
    if (config.mode == "csv") do
      run_csv_pipeline(config)
    else
      run_interactive_pipeline(config)
    end
  end


  ## run_csv_pipeline function for csv mode
  defp run_csv_pipeline(%{delimiter: delimiter, algorithms: algorithms, frequency: step_size} = _config) do
    window_sizes = Map.new(algorithms, &{&1, determine_window_size(&1)})

    # Initialize state for each algorithm
    initial_state =
      Enum.reduce(algorithms, %{}, fn algorithm, acc ->
        Map.put(acc, algorithm, %{window: SlidingWindow.new(window_sizes[algorithm]), result: nil})
      end)

    # Collect all points from the input stream
    points = Enum.to_list(InputParser.stream_input(delimiter))

    # Notify about insufficient points for each algorithm
    Enum.each(algorithms, fn algorithm ->
      required_points = determine_window_size(algorithm)
      provided_points = length(points)

      if provided_points < required_points do
        IO.puts("Algorithm: #{algorithm}")
        IO.puts("Number of points provided: #{provided_points}")
        IO.puts("You need to provide at least #{required_points} points for the #{algorithm} algorithm.")
      end
    end)

    # Process the collected points
    results =
      Enum.reduce(points, initial_state, fn point, state ->
        Enum.reduce(algorithms, state, fn algorithm, acc ->
          %{window: window, result: _} = Map.get(acc, algorithm)
          updated_window = SlidingWindow.add_point(window, point)
          if SlidingWindow.sufficient_points?(updated_window, window_sizes[algorithm]) do
            result = handle_interpolation(updated_window, algorithm, step_size)
            Map.put(acc, algorithm, %{window: updated_window, result: result})
          else
            Map.put(acc, algorithm, %{window: updated_window, result: nil})
          end
        end)
      end)


    # Print all results at the end
    Enum.each(results, fn {algorithm, %{result: result}} ->
      if result do
        print_results("#{algorithm} Interpolation", result)
      else
        IO.puts("No results for #{algorithm}.")
      end
    end)
  end

  ## run_interactive_pipeline function for interactive mode
  defp run_interactive_pipeline(%{algorithms: algorithms, frequency: step_size} = _config) do
    IO.puts("Ввод первых двух точек (X Y через пробел):")

    state = %{points: [], algorithms: algorithms, step_size: step_size, first_two_points: true}

    loop(state)
  end

  defp loop(%{first_two_points: true, points: points} = state) when length(points) < 2 do
      input = String.trim(IO.gets(""))
    case parse_point(input) do
      {:ok, point} ->
        updated_state = %{state | points: points ++ [point]}
        if length(updated_state.points) == 2 do
          updated_state.points
          |> Enum.sort_by(&elem(&1, 0)) # Sort by x
          |> process_points(updated_state)

          loop(%{updated_state | first_two_points: false})
        else
          loop(updated_state)
        end

      {:error, message} ->
        IO.puts("Ошибка: #{message}")
        loop(state)
    end
  end

  defp loop(state) do
    IO.puts("Введите следующую точку (X Y через пробел), или 'exit' для выхода:")

    input = String.trim(IO.gets("> "))
    case input do
      "exit" ->
        IO.puts("Выход из режима ввода.")

      _ ->
        case parse_point(input) do
          {:ok, point} ->
            updated_state = %{state | points: state.points ++ [point]}
            updated_state.points
            |> Enum.sort_by(&elem(&1, 0)) # Sort by x
            |> process_points(updated_state)
            loop(updated_state)

          {:error, message} ->
            IO.puts("Ошибка: #{message}")
            loop(state)
        end
    end
  end

  defp parse_point(input) do
    case String.split(input) do
      [x_str, y_str] ->
        with {x, ""} <- Float.parse(x_str),
             {y, ""} <- Float.parse(y_str) do
          {:ok, {x, y}}
        else
          _ -> {:error, "Некорректный ввод. Введите точки в формате 'X Y' (например, 1.0 2.0)."}
        end

      _ ->
        {:error, "Некорректный формат. Введите точки в формате 'X Y' (например, 1.0 2.0)."}
    end
  end

  defp process_points(points, %{algorithms: algorithms, step_size: step_size}) do
    for algorithm <- algorithms do
      IO.puts("\nРезультаты для алгоритма #{algorithm}:")
      process_algorithm(points, algorithm, step_size)
    end
  end

  defp process_algorithm(points, "linear", step_size) do
    last_points= Enum.take(points, -2)
    result = Interpolator.Linear.interpolate(last_points, step_size)
    print_results("Линейная интерполяция", result)
  end


  defp process_algorithm(points, "lagrange", step_size) do
    if length(points) >= 5 do
      result = Lagrange.interpolate(points, step_size)
      print_results("Интерполяция Лагранжа", result)
    else
      IO.puts("\nНедостаточно точек для интерполяции Лагранжа. Необходимо минимум 5 точек.")
    end
  end

  defp process_algorithm(points, "newton", step_size) do
    if length(points) >= 5 do
      result = Newton.interpolate(points, step_size)
      print_results("Интерполяция Ньютона", result)
    else
      IO.puts("\nНедостаточно точек для интерполяции Ньютона. Необходимо минимум 5 точек.")
    end
  end




  ## determine_window_size function
  defp determine_window_size(algo) do
    cond do
      algo == "linear" -> 2
      algo == "newton" -> 5
      algo == "lagrange" -> 5
      true -> nil  # Optional: handle unmatched cases
    end
  end



  defp handle_interpolation(window, algo, step_size) do
    points = SlidingWindow.get_points(window)

    cond do
      algo == "linear" -> Linear.interpolate(points, step_size)
      algo == "lagrange" -> Lagrange.interpolate(points, step_size)
      algo == "newton" -> Newton.interpolate(points, step_size)
      true -> {:error, "Unsupported algorithm"} # Optional: Handle unsupported cases
    end
  end



  defp print_results(label, results) do
    IO.puts("\n==== #{label} ====")
    IO.puts("X               Y")
    IO.puts(String.duplicate("-", 30))
    Enum.each(results, fn {x, y} -> IO.puts("#{Float.round(x, 2)}\t#{Float.round(y, 2)}") end)
    IO.puts(String.duplicate("=", 30))
  end
end
