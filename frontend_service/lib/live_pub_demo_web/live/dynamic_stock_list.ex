defmodule LivePubDemoWeb.DynamicStockList do
  use LivePubDemoWeb, :live_view

  alias Phoenix.PubSub

  require Logger

  @pubsub_name Trading.PubSub
  @pubsub_topic_common "trading:common"
  @pubsub_topic_stock_prefix "stock:"

  ### Callbacks ###

  @impl true
  def mount(params, session, socket) do
    from =
      Map.get(params, "from", "1")
      |> String.to_integer()

    to =
      Map.get(params, "to", "10")
      |> String.to_integer()

    session_id = Map.get(session, "session_id")

    stocks = gen_stock(from, to)
    stock_names = for {name, _} <- stocks, into: [], do: name
    PubSub.broadcast(@pubsub_name, @pubsub_topic_common, {:join, session_id, stock_names})

    stream_data =
      Enum.reduce(stocks, [], fn {name, stock}, acc ->
        [stock | acc]
      end)

    socket =
      socket
      |> stream(:stocks, stream_data)
      |> assign(:stock_data, stocks)
      |> assign(:from, from)
      |> assign(:to, to)
      |> assign(:cached, %{})
      |> assign(:counter, 0)
      |> assign(:page_title, "Dynamic Stock List (#{map_size(stocks)})")
      |> assign(:session_id, session_id)
      |> assign(:sleep_time, 1000)


    timer_ref =  Process.send_after(self(), :push_to_client, socket.assigns.sleep_time)

    {:ok, assign(socket, :timer_ref, timer_ref)}
  end

  @impl true
  def render(assigns) do
   ~H"""
    <section class="phx-hero">
    <div class="flex-row">
    <div>
    <p class="text-xl font-bold">List of stocks (range: <%= @from %> to <%= @to %>)</p>
    </div>

    <div class="grid gird-cols-5 sx:grid-cols-3 sm:grid-cols-3 md:grid-cols-5 xl:grid-cols-6 p-1  space-y-3 space-x-3" div id="stocks" phx-update="stream">
    <div :for={{id, stock} <- @streams.stocks} id={id}>
      <div class="container max-w-md rounded overflow-hidden shadow-lg bg-gray-300">
      <div class="px-2 py-2" >
          <div class="font-bold text-xl mb-2"><%= stock.stock_name %></div>
          <div class="flex flex-col text-sm text-gray-600 italic">
          <div class="" style={stock.color}> Price: <%= stock.stock_price %></div>
          <div class=""> Update:
          <%= if stock.update_at == "N/A" do %>
            <%= "N/A" %>
          <% else %>
           <%= NaiveDateTime.to_time(stock.update_at) %>
          <% end %>
          </div>
        </div>
      </div>
      <div class="px-6 pt-4 pb-2">
      </div>
      </div>
    </div>
    </div>

    <div class="px-10 py-10">
      <p class="text-l font-bold">Update Counter: <%= @counter %></p>
    </div>
    <div class="flex-col">
    <button type="button" class="text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:ring-blue-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-blue-600 dark:hover:bg-blue-700 focus:outline-none dark:focus:ring-blue-800" phx-click="update_10">
      update every 10ms
    </button>
    <button type="button" class="text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:ring-blue-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-blue-600 dark:hover:bg-blue-700 focus:outline-none dark:focus:ring-blue-800" phx-click="update_100">update every 100ms</button>
    <button type="button" class="text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:ring-blue-300 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-blue-600 dark:hover:bg-blue-700 focus:outline-none dark:focus:ring-blue-800" phx-click="update_1000">update every 1000ms</button>
    </div>
    </div>
    </section>
    """
  end

  @impl true
  def handle_info({:update_price, {stock_name, price, time}}, socket) do
    Logger.info("update stock price, id: #{stock_name}, price: #{price}, time: #{time}")

    # build new stock for cached
    stock = %{id: stock_name, stock_name: stock_name, stock_price: price, update_at: time}

    # update cached stock
    cached = Map.put(socket.assigns.cached, stock_name, stock)

    {:noreply, assign(socket, :cached, cached)}
  end

  @impl true
  def handle_info(:push_to_client, socket) do
    socket =
      if map_size(socket.assigns.cached) > 0 do
        Logger.info("update stock price for client, size: #{map_size(socket.assigns.cached)}")

        newStocks = update_stock(socket.assigns.stock_data, socket.assigns.cached)

        updated_stock_data =
          Enum.reduce(newStocks, socket.assigns.stock_data, fn stock, acc ->
            acc
            |> Map.put(stock.stock_name, stock)
          end)

        Logger.info("update stock price for client: #{inspect(newStocks)}")

        socket =
          Enum.reduce(newStocks, socket, fn stock, acc ->
            stream_insert(acc, :stocks, stock)
          end)

        Logger.info("stream stocks: #{inspect(socket.assigns.streams.stocks)}")

        socket
        |> update(:counter, &(&1 + Kernel.map_size(socket.assigns.cached)))
        |> assign(:cached, %{})
        |> assign(:stock_data, updated_stock_data)

      else
        socket
      end



    # send update for next time.
    timer_ref =  Process.send_after(self(), :push_to_client, socket.assigns.sleep_time)

    {:noreply, assign(socket, :timer_ref, timer_ref)}
  end

  @impl true
  def handle_event("update_10", _, socket) do
    Logger.info("set sleep time to 10")

    socket =
      socket
      |> assign(:sleep_time, 10)

      Process.cancel_timer(socket.assigns.timer_ref)

      timer_ref =  Process.send_after(self(), :push_to_client, socket.assigns.sleep_time)

      {:noreply, assign(socket, :timer_ref, timer_ref)}
  end

  @impl true
  def handle_event("update_100", _, socket) do
    Logger.info("set sleep time to 100")

    socket =
      socket
      |> assign(:sleep_time, 100)

    Process.cancel_timer(socket.assigns.timer_ref)

    timer_ref =  Process.send_after(self(), :push_to_client, socket.assigns.sleep_time)

    {:noreply, assign(socket, :timer_ref, timer_ref)}

  end

  @impl true
  def handle_event("update_1000", _, socket) do
    Logger.info("set sleep time to 1000")

    socket =
      socket
      |> assign(:sleep_time, 1000)

      Process.cancel_timer(socket.assigns.timer_ref)

      timer_ref =  Process.send_after(self(), :push_to_client, socket.assigns.sleep_time)

      {:noreply, assign(socket, :timer_ref, timer_ref)}
  end

  @impl true
  def terminate(reason, socket) do
    Logger.info("session: #{socket.assigns.session_id}, terminate: #{inspect reason}")

    Process.cancel_timer(socket.assigns.timer_ref)

    for stock_name <- Map.keys(socket.assigns.cached) do
      PubSub.unsubscribe(@pubsub_name, @pubsub_topic_stock_prefix <> stock_name)
    end

    {:ok, socket}
  end

  ### private functions ###

  defp update_stock(old, new) do
    Enum.map(new, fn {name, new_stock} ->
      old_stock = Map.get(old, name)
      update_stock_item(old_stock, new_stock)
    end)
  end

  defp update_stock_item(old, new) do
    Logger.info("update stock item, old: #{inspect old}, new: #{inspect new}")
    color =
      cond do
        old.stock_price == "N/A" ->
          "color: black"
        old.stock_price < new.stock_price ->
          "color: blue"
        old.stock_price > new.stock_price ->
          "color: red"
        true ->
          "color: black"
      end

    new
    |> Map.put(:color, color)
    |> Map.put(:changed, old.stock_price != new.stock_price)
  end

  defp gen_stock(from, to) do
    gen_stock(from, to, %{})
  end

  defp gen_stock(from, to, stocks) when from > to do
    stocks
  end

  defp gen_stock(from, to, stocks) do
    name = "stock_#{from}"
    stock =
      %{}
      |> Map.put_new(:stock_name, name)
      |> Map.put_new(:stock_price, "N/A")
      |> Map.put_new(:update_at, "N/A")
      |> Map.put_new(:color, "color: black")
      |> Map.put_new(:id, name)

    # subscribe stock for listening price changing
    PubSub.subscribe(@pubsub_name, @pubsub_topic_stock_prefix <> name)

    gen_stock(from + 1, to, Map.put_new(stocks, name, stock))
  end
end
