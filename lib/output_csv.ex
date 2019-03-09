defmodule CSVexport do
  @csv_header ["review_point", "title", "text"]
  def export_csv_from_sc_data(data, file_name, mode) do
    IO.puts("--> output csv: #{file_name}")
    file = File.open!(file_name, [:write, :utf8])
    case mode do
      true ->
        data
          |> Stream.map(&(_convert_any_data_to_csv_fromat(&1)))
          |> Stream.map(&(List.foldr(&1, [], fn row, acc -> row ++ acc end)))
          |> Enum.to_list
          |> Enum.reduce([], fn x, acc -> x ++ acc end)
          |> List.insert_at(0, @csv_header)
          |> CSV.encode
          |> Enum.each(&IO.write(file, &1))

      false ->
        data
          |> Stream.map(&(List.flatten(&1)))
          |> Stream.zip()
          |> Stream.map(&(Tuple.to_list(&1)))
          |> Enum.to_list
          |> List.insert_at(0, @csv_header)
          |> CSV.encode
          |> Enum.each(&IO.write(file, &1))
    end
  end

  defp _convert_any_data_to_csv_fromat([]), do: []
  defp _convert_any_data_to_csv_fromat([head | tail]) do
    convert = head
      |> Stream.map(&(List.flatten(&1)))
      |> Stream.zip()
      |> Stream.map(&(Tuple.to_list(&1)))
      |> Enum.to_list
    [convert] ++ _convert_any_data_to_csv_fromat(tail)
  end
end
