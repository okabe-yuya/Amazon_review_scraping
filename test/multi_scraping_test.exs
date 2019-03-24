defmodule MultiScrapingTest do
  use ExUnit.Case
  doctest MultiScraping
  import MultiProcess.CLI, only: [ parse_args: 1 ]

  test "-> parse_args: return normal arguments" do
    assert parse_args([true]) == true
  end

  test "-> parse_args: atributes string, return to_integer" do
    assert parse_args([false]) == false
  end

  test "-> parse_args: return no arguments" do
    assert parse_args(["--mode"]) == :help
  end
end
