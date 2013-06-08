defmodule YahooFinance do
  
  @moduledoc """
  YahooFinanace is used to access Yahoo Finance to retrieve Stock quote data.
  You can retrieve a standard quote, realtime quote or historical data.

  To get standard data call get_standard_quotes and pass a single symbol, a
  comma separated string of symbols or a list of symbols.

  To get a realtime quote call get_realtime_quotes and pass a single symbol, a
  comma separated string of symbols or a list of symbols.

  To get historical data call get_historical_quotes and either pass a start
  date and end date.

  You can also get historical data get_historical_quotes_using_days and pass
  a number of days to go backwards.
  """

  @default_read_timeout 5000

  @std_keys [ :s, :n, :l1, :d1, :t1, :c, :c1, :p2, :p, :o, :h, :g, :v, :m, :l, :t7, :a2, :b, :a ]

  @realtime_keys [ :s, :n, :b2, :b3, :k2, :k1, :c6, :m2, :j3 ]

  def std_keys, do: @std_keys
  def realtime_keys, do: @realtime_keys

  @doc """
  A record retuned by get_historical_quotes.
  """
  defrecord HistoricalQuote,
    symbol: nil,
    date: nil,
    open: 0.0,
    high: 0.0,
    low: 0.0,
    close: 0.0,
    volume: 0.0,
    adjClose: 0.0,
    recno: nil

  @doc """
  A record returned by get_standard_quotes or get_realtime_quotes. Not all
  fields are filled in. Only some of the fields are filled in for a real
  time quote.
  """
  defrecord StockQuote,
    symbol: nil,
    name: nil,
    lastTrade: 0.0,
    date: nil,
    time: nil,
    change: 0.0,
    changePoints: 0.0,
    changePercent: 0.0,
    previousClose: 0.0,
    open: 0.0,
    dayHigh: 0.0,
    dayLow: 0.0,
    volume: 0.0,
    dayRange: 0.0,
    lastTradeWithTime: 0.0,
    tickerTrend: nil,
    averageDailyVolume: 0,
    bid: 0.0,
    ask: 0.0,
    marketCap: 0.0

  @doc """
  The protocol for all quote types
  """
  defprotocol BaseQuote do
    @doc "functionality for all quote types"
    def initialize(q, hash, valarray)
    def valid?(q)
    def as_string(q)
  end

  def to_float(value) do
    case value do
      "N/A" -> value
      _ -> binary_to_float(value)
    end
  end

  def to_integer(value) do
    case value do
      "N/A" -> value
      _ -> binary_to_integer(value)
    end
  end


  defimpl BaseQuote, for: HistoricalQuote do
    def initialize(q, symbol, valarray) do
      q = q.update(symbol: String.upcase(symbol),
        date: Enum.at(valarray, 0),
        open: YahooFinance.to_float(Enum.at(valarray, 1)),
        high: YahooFinance.to_float(Enum.at(valarray, 2)),
        low: YahooFinance.to_float(Enum.at(valarray, 3)),
        close: YahooFinance.to_float(Enum.at(valarray, 4)),
        volume: YahooFinance.to_integer(Enum.at(valarray, 5)),
        adjClose: YahooFinance.to_float(Enum.at(valarray, 6)))
      if Enum.count(valarray) >= 8, do: q.recno(YahooFinance.to_integer(Enum.at(valarray, 7))), else: q
    end

    def valid?(q) do
      q.symbol != nil
    end

    def as_string(q) do
      "#HistoricalQuote symbol: #{q.symbol}"
    end
  end

  defimpl BaseQuote, for: StockQuote do

    defp key_method_map(q, value, :s), do: q.symbol(value)
    defp key_method_map(q, value, :n), do: q.name(value)
    defp key_method_map(q, value, :l1), do: q.lastTrade(value)
    defp key_method_map(q, value, :d1), do: q.date(value)
    defp key_method_map(q, value, :t1), do: q.time(value)
    defp key_method_map(q, value, :c), do: q.change(value)
    defp key_method_map(q, value, :k2), do: q.change(value)
    defp key_method_map(q, value, :c1), do: q.changePoints(value)
    defp key_method_map(q, value, :c6), do: q.changePoints(value)
    defp key_method_map(q, value, :p2), do: q.changePercent(value)
    defp key_method_map(q, value, :p), do: q.previousClose(value)
    defp key_method_map(q, value, :o), do: q.open(value)
    defp key_method_map(q, value, :h), do: q.dayHigh(value)
    defp key_method_map(q, value, :g), do: q.dayLow(value)
    defp key_method_map(q, value, :v), do: q.volume(value)
    defp key_method_map(q, value, :m), do: q.dayRange(value)
    defp key_method_map(q, value, :m2), do: q.dayRange(value)
    defp key_method_map(q, value, :l), do: q.lastTradeWithTime(value)
    defp key_method_map(q, value, :k1), do: q.lastTradeWithTime(value)
    defp key_method_map(q, value, :t7), do: q.tickerTrend(value)
    defp key_method_map(q, value, :a2), do: q.averageDailyVolume(value)
    defp key_method_map(q, value, :b), do: q.bid(value)
    defp key_method_map(q, value, :b3), do: q.bid(value)
    defp key_method_map(q, value, :a), do: q.ask(value)
    defp key_method_map(q, value, :b2), do: q.ask(value)
    defp key_method_map(q, value, :j3), do: q.marketCap(value)

    def initialize(q, keys, valarray) do
      keys |> Enum.zip(valarray) |> Enum.reduce(q, fn { key, value }, q ->
        if value != nil do
          q = key_method_map(q, value, key)
        end
        q
      end)
    end

    def valid?(q) do
      case q.name do
        nil -> false
        _ -> q.name != q.symbol
      end
    end

    def as_string(q) do
      "#StockQuote symbol: #{q.symbol} name: #{q.name}"
    end
  end

  @doc """
  Internal method to get realtime and standard quotes.
  """
  def get(symbols, format, timeout // @default_read_timeout) do
    symbols = cond do
      is_list(symbols) ->
        Enum.join(symbols, ",")
      is_binary(symbols) ->
        symbols
      true ->
        ""
    end
    response = cond do
      size(symbols)  > 0 ->
        HTTPotion.get("http://download.finance.yahoo.com/d/quotes.csv?s=#{symbols}&f=#{format}&e=.csv", [], [timeout: timeout])
      true ->
        ""
    end
    case response.status_code do
      200 ->
        String.strip(response.body)
      true ->
        ""
    end
  end

  @doc """
  Get Standard quotes. The following fields are filled in the returned record:
  symbol, name, lastTrade, date, time, change, changePoints, changePercent,
  previousClose, open, dayHigh, dayLow, volume, dayRange, lastTradeWithTime,
  tickerTrend, averageDailyVolume, bid, ask.

  Pass a single symbol, a comma seperated list of symbols without spaces, a
  list of symbols.
  """
  def get_standard_quotes(symbols) do
    get(symbols, Enum.join(@std_keys))
    |> CSV.parse
    |> Enum.map fn(row) ->
      YahooFinance.StockQuote.new |> YahooFinance.BaseQuote.initialize @std_keys, row
    end
  end

  @doc """
  Get reatime quotes. The following fields are filled in the returned record:
  symbol, name, ask, bid, change, lastTradeWithTime, changePoints, dayRange,
  marketCap.

  Pass a single symbol, a comma seperated list of symbols without spaces, a
  list of symbols.
  """
  def get_realtime_quotes(symbols) do
    get(symbols, Enum.join(@realtime_keys))
    |> CSV.parse
    |> Enum.map fn(row) ->
      YahooFinance.StockQuote.new |> YahooFinance.BaseQuote.initialize @realtime_keys, row
    end
  end

  @doc """
  Get historical quotes. The only field that may not be filled in is recno. All
  other HistoricalQuote fields will be filled in. Pass a symbol and the number
  of days to go back for data.
  """
  def get_historical_quotes(:days, symbol, days, timeout // @default_read_timeout) do
    end_date = :calendar.local_time
    start_date = :calendar.gregorian_seconds_to_datetime(:calendar.datetime_to_gregorian_seconds(end_date) - days * 86400)
    get_historical_quotes :dates, symbol, start_date, end_date, timeout
  end

  @doc """
  Get historical quotes. The only field that may not be filled in is recno. All
  other HistoricalQuote fields will be filled in. Pass a symbol and start date
  or start date and end date. The dates are in Erlang calendar datetime format.
  {{year,month,day}{hour,minute,second}} The time fields are ignored and can be
  zero.
  """
  def get_historical_quotes(:dates, symbol, start_date, end_date // nil, timeout // @default_read_timeout) do
    cond do
      {{sy,sm,sd},{_,_,_}} = start_date -> :ok
      {sy,sm,sd} = start_date -> :ok
    end
    case end_date do
      nil -> {ey,em,ed} = :erlang.date
      {{ey,em,ed},{_,_,_}} -> :ok
      {ey,em,ed} -> :ok
    end
    query = "http://itable.finance.yahoo.com/table.csv?s=#{symbol}&g=d&a=#{sm-1}&b=#{sd}&c=#{sy}&d=#{em-1}&e=#{ed}&f=#{ey}"

    response = HTTPotion.get(query, [], [timeout: timeout])
    cond do
      response.status_code in 200..299 ->
        response.body
        |> CSV.parse(",", "\"", 1)
        |> Enum.map(fn(row) ->
          YahooFinance.HistoricalQuote.new |> YahooFinance.BaseQuote.initialize symbol, row
        end)
      true -> []
    end
  end
end
  