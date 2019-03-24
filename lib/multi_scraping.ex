defmodule MultiScraping do
  @user_agent [ {"User-agent", "elixir-lang"} ]
  @limit_review_one_page 8
  @result_csv_name "result.csv"
  import CSVexport, only: [export_csv_from_sc_data: 2]
  def process_fetch(scheduler) do
    send scheduler, { :ready, self() }
    receive do
      { :fetch, url, mode, client } ->
        send client, { :answer, fetch_from_amazon(url, mode), self() }
        process_fetch(scheduler)
      { :shutdown } -> exit(:normal)
        # code
    end
  end

  def fetch_from_amazon(url, mode) when mode === false do
    res = url
      |> make_page_query(1)
      |> HTTPoison.get!(@user_agent)
    # file_name = decide_unique_name()
    case_single_page_only(res.body)
      |> export_csv_from_sc_data(@result_csv_name)
  end

  def fetch_from_amazon(url, mode) when mode === true do
    res = url
      |> make_page_query(1)
      |> HTTPoison.get!(@user_agent)
    total_review_page =
      res.body
        |> pull_total_review_num("span.totalReviewCount")
        |> count_total_page
    # file_name = decide_unique_name()
    case total_review_page > 1 do
      true ->
        IO.puts("--> many page")
        case_many_page(url, total_review_page)
          |> export_csv_from_sc_data(@result_csv_name)

      false ->
        IO.puts("--> single page")
        case_single_page_only(res.body)
          |> export_csv_from_sc_data(@result_csv_name)
    end
  end

  def case_single_page_only(res_body) do
    point = pull_review_point(res_body)
    title = pull_selecter_text(res_body, "a.review-title-content")
    text = pull_selecter_text(res_body, "span.review-text")
    Enum.zip([
      point,
      title,
      text
    ])
  end

  def case_many_page(url, limit) do
    _case_many_page(url, limit, 1)
  end
  defp _case_many_page(_, limit, accum) when limit === accum - 1, do: []
  defp _case_many_page(url, limit, accum) do
    res = url
      |> make_page_query(accum)
      |> HTTPoison.get!(@user_agent)
    res_body = res.body
    point = pull_review_point(res_body)
    title = pull_selecter_text(res_body, "a.review-title-content")
    text = pull_selecter_text(res_body, "span.review-text")
    res = Enum.zip([
      point,
      title,
      text
    ])
    res ++ _case_many_page(url, limit, accum + 1)
  end

  def pull_selecter_text(res_body, selecter) do
    res_body
      |> Floki.find(selecter)
      |> Enum.map(&(Floki.text(&1)))
      |> Enum.map(&(String.replace(&1, "\n", "")))
  end

  def pull_total_review_num(res_body, selecter) do
    res_body
      |> Floki.find(selecter)
      |> Floki.text()
      |> String.replace(",", "")
      |> String.to_integer
  end

  def pull_review_point(res_body) do
    res_body
      |> Floki.find("div.reviews-content")
      |> Floki.find("i.review-rating")
      |> Floki.find("span.a-icon-alt")
      |> Enum.map(&(Floki.text(&1)))
      |> Enum.map(&(_shape_review_data(&1)))
  end

  defp _shape_review_data(str_data) do
    str_data
      |> String.replace("5つ星のうち", "")
      |> String.at(0)
      |> String.to_integer
  end

  def make_page_query(url, number) do
    String.replace(url, "/dp", "/product-reviews") <> "&reviewerType=all_reviews&pageNumber=#{number}"
  end

  def decide_unique_name(format \\ ".csv") do
    { date_info, day_info } = :calendar.local_time()
    { year, month, day } = date_info
    { hour, minute, second } = day_info
    join = [year, month, day, hour, minute, second]
      |> Enum.map(fn s ->
        if 10 > s do
          "0" <> Integer.to_string(s)
        else
          Integer.to_string(s)
        end
      end)
      |> Enum.reduce(&(&2 <> &1))
    join <> format
  end

  def count_total_page(total_review_num) do
    rest = rem(total_review_num, @limit_review_one_page)
    page_num = div(total_review_num, @limit_review_one_page)
    case rest do
      0 -> page_num
      _ -> page_num + 1
    end
  end
end

defmodule MakeProcessForScraping do
  def read_url_list_from_txt(file_name) do
    { _, data } = File.read(file_name)
    String.split(data, "\n")
  end

  def multi_run(mode) do
    read_url_list_from_txt("target_url.txt")
      |> Enum.map(&(Task.async(MultiScraping.fetch_from_amazon(&1, mode))))
  end

  def main(mode) do
    file_list = read_url_list_from_txt("target_url.txt")
    make_process_num = Enum.count(file_list)
    { time, _result } = :timer.tc(
      Scheduler, :run,
      [make_process_num, MultiScraping, :process_fetch, file_list, mode]
    )
    IO.puts("time: #{time / 1000000}")
  end

  def no_process(mode) do
    file_list = read_url_list_from_txt("target_url.txt")
    Enum.map(file_list, &(MultiScraping.fetch_from_amazon(&1, mode)))
  end
end

defmodule Scheduler do
  def run(num_process, module, func, urls, mode) do
    (1..num_process)
      |> Enum.map(fn _ -> spawn(module, func, [self()]) end)
      |> suchedule_processes(urls, mode)
  end

  def suchedule_processes(process, urls, mode) do
    receive do
      { :ready, pid } when urls != [] ->
        [head | tail] = urls
        send pid, { :fetch, head, mode, self() }
        suchedule_processes(process, tail, mode)

      { :ready, pid } ->
        send pid, { :shutdown }
        if length(process) > 1 do
          suchedule_processes(List.delete(process, pid), urls, mode)
        end

      { :done, is_success, _pid } ->
        case is_success do
          true -> suchedule_processes(process, urls, mode)
          false -> :error
        end
    end
  end
end
