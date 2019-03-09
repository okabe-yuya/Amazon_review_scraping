defmodule AmazonReviewScTest do
  use ExUnit.Case
  doctest AmazonReviewSc
  import AmazonReviewSc.CLI, only: [ parse_args: 1 ]
  alias AmazonReviewSc

  test "-> parse_args: return normal arguments" do
    assert parse_args([true]) == true
  end

  test "-> parse_args: atributes string, return to_integer" do
    assert parse_args([false]) == false
  end

  test "-> parse_args: return no arguments" do
    assert parse_args(["--mode"]) == :help
  end

  test "-> convert URL to page query URL" do
    sample_url = "https://www.amazon.co.jp/%E3%83%AB%E3%83%9F%E3%83%8A%E3%82%B9-LED%E3%82%B7%E3%83%BC%E3%83%AA%E3%83%B3%E3%82%B0%E3%83%A9%E3%82%A4%E3%83%88-6%E7%95%B3-10%E6%AE%B5%E9%9A%8E-AM-T32DX/dp/B07JKJ45ZY/ref=cm_cr_arp_d_product_top?ie=UTF8"
    convert_url = AmazonReviewSc.make_page_query(sample_url, 1)
    expect_url = "https://www.amazon.co.jp/%E3%83%AB%E3%83%9F%E3%83%8A%E3%82%B9-LED%E3%82%B7%E3%83%BC%E3%83%AA%E3%83%B3%E3%82%B0%E3%83%A9%E3%82%A4%E3%83%88-6%E7%95%B3-10%E6%AE%B5%E9%9A%8E-AM-T32DX/product-reviews/B07JKJ45ZY/ref=cm_cr_arp_d_product_top?ie=UTF8&reviewerType=all_reviews&pageNumber=1"
    assert convert_url == expect_url
  end

  test "-> calculate total review page(if has many page)" do
    total_review_num = 50
    cal_page_num = AmazonReviewSc.count_total_page(total_review_num)
    assert cal_page_num == 7
  end

  test "-> calculate total review page(if hasn't many page)" do
    total_review_num = 7
    cal_page_num = AmazonReviewSc.count_total_page(total_review_num)
    assert cal_page_num == 1
  end

  test "-> create target url list from .txt file string" do
    from_text = AmazonReviewSc.read_url_list_from_txt("./test/for_test_url.txt")
    IO.inspect(from_text)
    expect = List.duplicate("https://google.com", 4)
    assert from_text == expect
  end

  test "-> create csv, success" do
    s_key = :ok
    s_judge = AmazonReviewSc.create_csv_judge(s_key)
    assert s_judge == :ok
  end

  test "-> create csv, failure" do
    f_key = :error
    f_judge = AmazonReviewSc.create_csv_judge(f_key)
    assert f_judge == :error
  end

end
