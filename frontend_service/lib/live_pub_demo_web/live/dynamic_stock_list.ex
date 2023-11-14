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

    socket =
      socket
      |> assign(:stocks, stocks)
      |> assign(:from, from)
      |> assign(:to, to)
      |> assign(:cached, %{})
      |> assign(:counter, 0)
      |> assign(:page_title, "Dynamic Stock List (#{map_size(stocks)})")
      |> assign(:session_id, session_id)
      |> assign(:sleep_time, 300)


    timer_ref =  Process.send_after(self(), :push_to_client, socket.assigns.sleep_time)

    {:ok, assign(socket, :timer_ref, timer_ref)}
  end

  @impl true
  def render(assigns) do
   ~H"""
    <section class="phx-hero">
    <h1>List of stocks (range: <%= @from %> to <%= @to %>)</h1>
    <table>
        <tr>
            <td>Stock</td>
            <td>Price</td>
            <td>Time</td>
        </tr>
        <%= for {_, stock} <- @stocks do %>
           <.live_component module={LivePubDemoWeb.StockItem} id={stock.stock_name} stock={stock} />
        <% end %>
    </table>
    <p>Update Counter: <%= @counter %></p>
    <button phx-click="update_10">update every 10ms</button>
    <button phx-click="update_100">update every 100ms</button>
    <button phx-click="update_1000">update every 1000ms</button>
    </section>
    """
  end

  @impl true
  def handle_info({:update_price, {stock_name, price, time}}, socket) do
    Logger.info("update stock price, id: #{stock_name}")

    # build new stock for cached
    stock = %{stock_name: stock_name, stock_price: price, update_at: time}

    # update cached stock
    cached = Map.put(socket.assigns.cached, stock_name, stock)

    {:noreply, assign(socket, :cached, cached)}
  end

  @impl true
  def handle_info(:push_to_client, socket) do
    socket =
      if map_size(socket.assigns.cached) > 0 do
        Logger.info("update stock price for client, size: #{map_size(socket.assigns.cached)}")

        newStocks = Map.merge(socket.assigns.stocks, socket.assigns.cached, &update_stock/3)

        socket
        |> assign(:stocks, newStocks)
        |> update(:counter, &(&1 + Kernel.map_size(socket.assigns.cached)))
        |> assign(:cached, %{})

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

    for stock_name <- Map.keys(socket.assigns.stocks) do
      PubSub.unsubscribe(@pubsub_name, @pubsub_topic_stock_prefix <> stock_name)
    end

    {:ok, socket}
  end

  ### private functions ###

  defp update_stock(_key, old, new) do
    color =
      cond do
        old.stock_price < new.stock_price ->
          "color: blue"
        old.stock_price > new.stock_price ->
          "color: red"
        true ->
          "color: black"
      end

    Map.put(new, :color, color)
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

    # subscribe stock for listening price changing
    PubSub.subscribe(@pubsub_name, @pubsub_topic_stock_prefix <> name)

    gen_stock(from + 1, to, Map.put_new(stocks, name, stock))
  end
end
