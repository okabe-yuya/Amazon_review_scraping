defmodule AmazonReviewSc.CLI do
  import AmazonReviewSc, only: [fetch_from_amazon: 1]
  def main(argv) do
    argv
      |> parse_args
      |> fetch_from_amazon
  end
  def parse_args(argv) do
    parse = OptionParser.parse(argv, switches: [mode: :boolean])
    case parse do
      { [ mode: true ], _, _ } -> false
      { _, [key], _ } -> _convert_str_to_boolean(key)
      _ -> false
    end
  end

  defp _convert_str_to_boolean(str) do
    case str do
      "true" -> true
      "false" -> false
      _ -> false
    end
  end
end
