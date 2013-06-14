Code.require_file "test_helper.exs", __DIR__

defmodule YahooFinanceTest do
  use ExUnit.Case

  test "yahoo finance" do
    q = YahooFinance.get_standard_quotes("FB") |> Enum.at 0
    assert(q.symbol == "FB")
    assert(q.name == "Facebook, Inc.")

    sq = YahooFinance.get_standard_quotes(["FB", "AAPL"])
    q = sq |> Enum.at 0
    assert(q.symbol == "FB")
    assert(q.name == "Facebook, Inc.")
    q = sq |> Enum.at 1
    assert(q.symbol == "AAPL")
    assert(q.name == "Apple Inc.")

    YahooFinance.get_realtime_quotes(["FB", "AAPL"])
    q = YahooFinance.get_realtime_quotes("FB") |> Enum.at 0
    assert(q.symbol == "FB")
    assert(q.name == "Facebook, Inc.")

    rq = YahooFinance.get_realtime_quotes(["FB", "AAPL"])
    q = rq |> Enum.at 0
    assert(q.symbol == "FB")
    assert(q.name == "Facebook, Inc.")
    q = rq |> Enum.at 1
    assert(q.symbol == "AAPL")
    assert(q.name == "Apple Inc.")

    hq = YahooFinance.get_historical_quotes(:days, "FB", 8, 3000)
    assert Enum.count(hq) > 0
    assert Enum.at(hq, 0).symbol == "FB"
    assert Enum.at(hq, 0).date != nil
    assert YahooFinance.BaseQuote.valid? Enum.at(hq, 0)

    end_date = :calendar.local_time
    start_date = :calendar.gregorian_seconds_to_datetime(:calendar.datetime_to_gregorian_seconds(end_date) - 7 * 86400)

    hq = YahooFinance.get_historical_quotes(:dates, "FB", start_date, end_date, 3000)
    assert Enum.count(hq) > 0
    assert Enum.at(hq, 0).symbol == "FB"
    assert Enum.at(hq, 0).date != nil
    assert YahooFinance.BaseQuote.valid? Enum.at(hq, 0)
  end

  test "StockQuote" do
    vals = CSV.parse(YahooFinance.get("FB", "snl1d1t1cc1p2pohgvmlt7a2ba"))
    q = YahooFinance.StockQuote.new
    q = YahooFinance.BaseQuote.initialize(q, YahooFinance.std_keys, Enum.at(vals, 0))
    assert(q.symbol == "FB")
    assert(q.name == "Facebook, Inc.")
    assert YahooFinance.BaseQuote.valid? q

    refute YahooFinance.BaseQuote.valid? YahooFinance.StockQuote.new
  end

  test "HistoricalQuote" do
    q = YahooFinance.HistoricalQuote.new
    q = YahooFinance.BaseQuote.initialize(q, "fb", ["2013-05-29", "23.13", "23.43", "23.03", "23.23", "3562345", "23.23"])
    assert(q.symbol == "FB")
    assert(q.date == "2013-05-29")
    assert(q.open == 23.13)
    assert(q.high == 23.43)
    assert(q.low == 23.03)
    assert(q.close == 23.23)
    assert(q.volume == 3562345)
    assert(q.adjClose == 23.23)
    assert(q.recno == nil)

    q = YahooFinance.HistoricalQuote.new
    q = YahooFinance.BaseQuote.initialize(q, "fb", ["2013-05-29", "23.13", "23.43", "23.03", "23.23", "0", "23.23", "1234"])
    assert(q.symbol == "FB")
    assert(q.date == "2013-05-29")
    assert(q.open == 23.13)
    assert(q.high == 23.43)
    assert(q.low == 23.03)
    assert(q.close == 23.23)
    assert(q.volume == 0)
    assert(q.adjClose == 23.23)
    assert(q.recno == 1234)
  end
end
