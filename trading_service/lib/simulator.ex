defmodule Trading.Simulator do
  use GenServer, restart: :permanent, shutdown: 5_000

  require Logger

  alias Trading.StockDelivery, as: Public

  ### APIs ###

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def set_sleep_time(sleep_time) do
    GenServer.cast(__MODULE__, {:update_sleep_time, sleep_time})
  end

  def range_change(range) do
    GenServer.cast(__MODULE__, {:update_range_change, range})
  end

  def num_change(num) do
    GenServer.cast(__MODULE__, {:update_num_change, num})
  end

  def set_stocks(price) do
    GenServer.cast(__MODULE__, {:set_price_all, price})
  end

  ### Callbacks ###

  @impl true
  def init(_) do
    table = :ets.new(:stocks_table, [:set, :protected, :named_table])
    num = 10_000
    # make number of stock (= num) with default price is 10.
    init_stock(num, table)

    # send update event to simulate stock price change overtime.
    ref = Process.send_after(self(), :update_price, 300)

    # init state.
    state =
      %{}
      |> Map.put_new(:table, table)
      |> Map.put_new(:num_stocks, num)
      |> Map.put_new(:sleep_time, 1_000)
      |> Map.put_new(:num_change, div(num, 1000))
      |> Map.put_new(:range_change, 10)
      |> Map.put_new(:timer_ref, ref)

    {:ok, state}
  end

  @impl true
  def handle_cast( {:update_range_change, range}, state) do
    {:noreply, Map.put(state, :update_range_change, range)}
  end

  @impl true
  def handle_cast({:update_sleep_time, sleep_time}, state) do
    # refresh update time.
    Process.cancel_timer(state.timer_ref)
    ref = Process.send_after(self(), :update_price, sleep_time)

    Logger.debug("update sleep time, new sleep time: #{sleep_time}")

    state =
      state
      |> Map.put(:sleep_time, sleep_time)
      |> Map.put(:timer_ref, ref)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:update_num_change, num}, state) do
    {:noreply, Map.put(state, :num_change, num)}
  end

  @impl true
  def handle_cast( {:set_price_all, price}, %{num_stocks: num, table: table} = state) do
    set_stock(num, price, table)

    {:noreply, state}
  end

  @impl true
  def handle_info(:update_price, %{num_stocks: max_num, range_change: range, num_change: :all, table: table} = state) do
    # get random stock list.
    stocks =
      Enum.map(1..max_num, fn n -> "stock_#{n}" end )

    # update price for stocks
    update_price(stocks, range, table)

    Logger.debug("update all stock price, size: #{max_num}, range: #{range}, num_change: all")

    # send update for next time.
    ref = Process.send_after(self(), :update_price, state.sleep_time)

    state =
      state
      |> Map.put(:timer_ref, ref)

    {:noreply, state}
  end

  @impl true
  def handle_info(:update_price, %{num_stocks: max_num, range_change: range, num_change: num_change, table: table} = state) do
    # get random stock list.
    stocks =
      get_random_stocks(num_change, max_num)
      |> Enum.uniq()

    # update price for stocks
    update_price(stocks, range, table)


    Logger.debug("update all stock price, size: #{length(stocks)}, range: #{range}, num_change: #{num_change}")


    # send update for next time.
    ref = Process.send_after(self(), :update_price, state.sleep_time)

    state =
      state
      |> Map.put(:timer_ref, ref)

    {:noreply, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.debug("shutdown simulator, reason: #{inspect reason}")

    # cancel update.
    Process.cancel_timer(state.timer_ref)

    :ok
  end

  ### Private ###

  # init number of stock with default price is 10.
  defp init_stock(0, _table) do
    :ok
  end

  defp init_stock(num, table) do
    name = "stock_#{num}"
    stock = {name, 100, NaiveDateTime.local_now()}
    # save initiated stock to cache.
    :ets.insert(table, stock)

    init_stock(num - 1, table)
  end

    # init number of stock with default price is 10.
    defp set_stock(0, _price, _table) do
      :ok
    end

    defp set_stock(num, price, table) do
      name = "stock_#{num}"
      stock = {name, price, NaiveDateTime.local_now()}
      # save initiated stock to cache.
      :ets.insert(table, stock)

      # broadcast to frontend
      #Public.update_stock(stock)
      Public.direct_send(stock)

      set_stock(num - 1, price, table)
    end


  # random a price change.
  defp update_price([], _range, _table) do
    :ok
  end
  defp update_price([name | rest], range, table) do
    [{_, price, _}] = :ets.lookup(table, name)

    changed = div(range, 2) - Enum.random(1..range)

    price =
      case price + changed do
        n when n < 1 -> 1 # don't go to zero or negative number
        n -> n
      end

    time = NaiveDateTime.local_now()
    stock = {name, price, time}
    :ets.insert(table, stock)

    # broadcast to frontend
   # Public.update_stock(stock)
    Public.direct_send(stock)



    update_price(rest, range, table)
  end

  # generate a random stock.
  defp get_random_stocks(num, max_num) do
    get_random_stocks(num, max_num, [])
  end
  defp get_random_stocks(0, _, result) do
    result
  end
  defp get_random_stocks(num, max_num, result) do
    num = Enum.random(1..max_num)
    name = "stock_#{num}"
    get_random_stocks(num - 1, max_num, [ name | result] )
  end
end
