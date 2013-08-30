defmodule YahooFinance.Mixfile do
  use Mix.Project

  def project do
    [ app: :yahoo_finance,
      version: "0.1.0",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    [ applications: [:inets] ]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [{:elixir_csv, "0.1.1", [github: "baldmountain/elixir_csv"]},
    {:"elixir-datetime", "0.1", [github: "alco/elixir-datetime"]}]
  end
end
