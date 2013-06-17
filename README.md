# YahooFinance

YahooFinanace is used to access Yahoo Finance to retrieve Stock quote data.
You can retrieve a standard quote, real time quote or historical data.

To get standard data call get_standard_quotes and pass a single symbol, a
comma separated string of symbols or a list of symbols.

To get a realtime quote call get_realtime_quotes and pass a single symbol, a
comma separated string of symbols or a list of symbols.

To get historical data call get_historical_quotes and pass a number of days
to go backwards. Or, call get_historical_quotes_using_dates and pass a start
date and an optional end date.
