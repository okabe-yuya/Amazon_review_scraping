defmodule CSVexport do
  # @csv_header ["review_point", "title", "text"]
  def export_csv_from_sc_data(data, file_name) do
    IO.puts("--> output csv: #{file_name}")
    file = File.open!(file_name, [:append, :utf8])
    data
      |> Enum.map(&(Tuple.to_list(&1)))
      # |> List.insert_at(0, @csv_header) add head column
      |> CSV.encode
      |> Enum.each(&IO.write(file, &1))
    :nice
  end
end
