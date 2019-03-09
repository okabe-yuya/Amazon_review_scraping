defmodule AmazonReviewSc do
  @user_agent [ {"User-agent", "elixir-lang: n2i.okabe.y@gmail.com"} ]
  @limit_review_one_page 8
  import CSVexport, only: [export_csv_from_sc_data: 3]

  def fetch_from_amazon(mode) when mode === false do
    IO.puts("--> mode: only first review page...")
    res_html = read_url_list_from_txt("target_url.txt")
      |> Stream.map(&(make_page_query(&1, 1)))
      |> Stream.map(&(HTTPoison.get!(&1, @user_agent).body))
      |> Enum.to_list
    review_point = take_review_point(res_html)
    title = take_review_user_text(res_html, "span.cr-original-review-content")
    text = take_review_user_text(res_html, "span.review-text")
    concat_data = [
      review_point,
      title,
      text,
    ]
    create_csv = export_csv_from_sc_data(concat_data, "result.csv", mode)
    create_csv_judge(create_csv)
  end

  def fetch_from_amazon(mode) when mode === true do
    IO.puts("--> mode: all review page...")
    IO.puts("--> start: count total reviews and fetch review page from amazon ")
    target_url = read_url_list_from_txt("target_url.txt")
    first_res_html = target_url
      |> Stream.map(&(make_page_query(&1, 1)))
      |> Stream.map(&(HTTPoison.get!(&1, @user_agent).body))
      |> Enum.to_list

    res = take_review_user_text(first_res_html, "span.totalReviewCount")
      |> List.flatten()
      |> Stream.map(&(count_total_page(String.to_integer(&1))))
      |> Stream.zip(target_url)
      |> Enum.to_list
      |> Enum.map(&(check_all_review_page(&1)))

      create_csv = export_csv_from_sc_data(res, "result.csv", mode)
      create_csv_judge(create_csv)
  end

  def check_all_review_page({ total_page_num, url }) do
    _check_all_review_page({ total_page_num, url }, 1)
  end

  def _check_all_review_page({ total_page_num, _url }, accum) when total_page_num === accum - 1, do: []
  def _check_all_review_page({ total_page_num, url }, accum) do
    query_url = make_page_query(url, accum)
    IO.puts("--> fetch: #{query_url}")
    res_html = HTTPoison.get!(query_url, @user_agent).body
    review_point = take_review_point([res_html])
    title = take_review_user_text([res_html], "span.cr-original-review-content")
    text = take_review_user_text([res_html], "span.review-text")
    result = [
      review_point,
      title,
      text
    ]
    [result] ++ _check_all_review_page({ total_page_num, url }, accum+1)
  end

  def take_review_point(html) do
    convert = html |> Enum.map(&(Floki.find(&1, "span.a-icon-alt")))
    _take_review_point(convert)
  end

  defp _take_review_point([]), do: []
  defp _take_review_point([head | tail]) do
    convert = head
      |> Stream.map(&(elem(&1, 2)))
      |> Stream.map(&(Floki.text(&1)))
      |> Stream.map(&(String.replace(&1, "5つ星のうち", "")))
      |> Stream.map(&(String.at(&1, 0)))
      |> Enum.to_list
    res = Enum.slice(convert, 3..Enum.count(convert)) |> Enum.slice(0..7)
    [res] ++ _take_review_point(tail)
  end

  def take_review_user_text(html, floki_selector) do
    convert = html |> Enum.map(&(Floki.find(&1, floki_selector)))
    _take_review_user_text(convert)
  end

  defp _take_review_user_text([]), do: []
  defp _take_review_user_text([head | tail]) do
    res = head
      |> Stream.map(&(elem(&1, 2)))
      |> Stream.map(&(String.replace(Floki.text(&1), "\n", "")))
      |> Enum.to_list
    [res] ++ _take_review_user_text(tail)
  end

  def make_page_query(url, number) do
    String.replace(url, "/dp", "/product-reviews") <> "&reviewerType=all_reviews&pageNumber=#{number}"
  end

  def read_url_list_from_txt(file_name) do
    { _, data } = File.read(file_name)
    String.split(data, "\n")
  end

  def count_total_page(total_review_num) do
    rest = rem(total_review_num, @limit_review_one_page)
    page_num = div(total_review_num, @limit_review_one_page)
    case rest do
      0 -> page_num
      _ -> page_num + 1
    end
  end

  def create_csv_judge(result) do
    case result do
      :ok ->
        IO.puts("--> success create csv")
        IO.puts("--> all finished")
        :ok
      :error ->
        IO.puts("--> failed cretae csv #{:error}")
        IO.puts("--> all finished")
        :error
    end
  end
end
