defmodule Trading.Simulator do
  use GenServer, restart: :permanent, shutdown: 5_000

  require Logger

  alias Trading.StockDelivery, as: Public

  ### APIs ###

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def frequency(sleep_time) do
    GenServer.cast(__MODULE__, {:update_sleep_time, sleep_time})
  end

  def range_change(range) do
    GenServer.cast(__MODULE__, {:update_range_change, range})
  end

  def num_change(num) do
    GenServer.cast(__MODULE__, {:update_num_change, num})
  end

  def reset_stocks() do
    GenServer.cast(__MODULE__, :reset_stocks)
  end

  ### Callbacks ###

  @impl true
  def init(_) do
    table = :ets.new(:stocks, [:set, :protected])
    num = 10_000
    # make number of stock (= num) with default price is 10.
    init_stock(num, table)

    # send update event to simulate stock price change overtime.
    ref = Process.send_after(self(), :update_price, 1_000)

    # init state.
    state =
      %{}
      |> Map.put_new(:table, table)
      |> Map.put_new(:num_stocks, num)
      |> Map.put_new(:sleep_time, 300)
      |> Map.put_new(:num_change, div(num, 10))
      |> Map.put_new(:range_change, 3)
      |> Map.put_new(:timer_ref, ref)

    {:ok, state}
  end

  @impl true
  def handle_cast({:update_sleep_time, sleep_time}, state) do
    {:noreply, Map.update(state, :sleep, sleep_time)}
  end

  @impl true
  def handle_cast( {:update_range_change, range}, state) do
    {:noreply, Map.update(state, :update_range_change, range)}
  end

  @impl true
  def handle_cast({{:update_sleep_time, sleep_time}, element}, state) do
    # refresh update time.
    Process.cancel_timer(state.timer_ref)
    ref = Process.send_after(self(), :update_price, sleep_time)

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
  def handle_cast(:reset_stocks, %{num_stocks: num, table: table} = state) do
    init_stock(num, table)

    {:noreply, state}
  end

  @impl true
  def handle_info(:update_price, %{num_stocks: max_num, range_change: range, num_change: num_change, sleep_time: sleep_time, table: table} = state) do
    # get random stock list.
    stocks = get_random_stocks(num_change, max_num)

    # update price for stocks
    update_price(stocks, range, table)

    # send update for next time.
    ref = Process.send_after(self(), :update_price, sleep_time)

    {:noreply, Map.put(state, :timer_ref, ref)}
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
    name = "Stock_#{num}"
    stock = {name, 10, NaiveDateTime.local_now()}
    # save initiated stock to cache.
    :ets.insert(table, stock)

    init_stock(num - 1, table)
  end

  # random a price change.
  defp update_price([], _range, _table) do
    :ok
  end
  defp update_price([name | rest], range, table) do
    [{_, price, _}] = :ets.lookup(table, name)

    changed = div(price, 2) - :rand.uniform(range)

    price =
      case price + :rand.uniform(range) do
        n when n < 1 -> 1 # don't go to zero or negative number
        n -> n
      end

    time = NaiveDateTime.local_now()
    stock = {name, price, time}
    :ets.insert(table, stock)

    # broadcast to frontend
    Public.update_stock(stock)

    update_price(rest, range, table)
  end

  # generate a random stock.
  defp get_random_stocks(num, max_num) do
    get_random_stocks(num, max_num, [])
  end
  defp get_random_stocks(0, max_num, result) do
    result
  end
  defp get_random_stocks(num, max_num, result) do
    num = :rand.uniform(max_num)
    name = "Stock_#{num}"
    get_random_stocks(num - 1, max_num, [ name | result] )
  end
end
