defmodule Trading do
  @moduledoc """
  Documentation for `Trading`.
  """

  alias Trading.Simulator

  @doc """
  Reset all stock prices and publish to frontends.

  ## Examples

      iex> Trading.set_all_stock_prices(100)

  """
  def set_all_stock_prices(price) when is_integer(price) and price > 0 do
    Simulator.set_stocks(price)
  end

  @doc """
  Reset all stock prices and publish to frontends.

  ## Examples

      iex> Trading.set_all_stock_prices(100)

  """
  def set_sleep_time(time) when is_integer(time) and time > 0 do
    Simulator.set_sleep_time(time)
  end

  @doc """
  Set number of stocks will be changed price.

  ## Examples

      iex> Trading.num_change(100)

  """
  def num_change(num) when (is_integer(num) and num > 0) or (num == :all) do
    Simulator.num_change(num)
  end
end
