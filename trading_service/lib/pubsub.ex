defmodule Trading.StocksManager do
  use GenServer, restart: :permanent, shutdown: 5_000

  @pubsub_name Trading.Pubsub
  @pubsub_topic_common "trading:common"
  @pubsub_topic_stock_prefix "stock"

  require Logger

  alias Phoenix.PubSub

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def update_stock(stock, price) do
    GenServer.cast(__MODULE__, {:update_stock, stock, price})
  end

  @impl true
  def init(_) do
    # subsribe pubsub to get common info from frontend service.
    PubSub.subscribe(@pubsub_name, @pubsub_topic_common)
    Logger.debug("trading subscribed #{inspect @pubsub_topic_common}")

    {:ok, %{}}
  end

  # managing frontend
  @impl true
  def handle_info({:join, frontend_id}, state) do
    Logger.info("frontend join, id: #{frontend_id}")

    {:noreply,  Map.put(state, frontend_id, DateTime.now())}
  end

  def handle_info(unknown_msg, state) do
    Logger.debug("unknown msg, #{inspect unknown_msg}")

    {:noreply, state}
  end

  @impl true
  def handle_cast({:update_stock, stock, price}, state) do
    # send new price for all subscribers.
    PubSub.broadcast(@pubsub_name, @pubsub_topic_stock_prefix <> stock, {:price, price, DateTime.now()})

    {:noreply, state}
  end

  def handle_cast({:disconnect, frontend_id}, state) do
    {:noreply, Map.delete(state, frontend_id)}
  end

  @impl true
  def terminate(reason, _state) do
    Logger.debug("shutdown trading handling, reason: #{inspect reason}")
    PubSub.unsubscribe(@pubsub_name, @pubsub_topic_common)

    :ok
  end
end
