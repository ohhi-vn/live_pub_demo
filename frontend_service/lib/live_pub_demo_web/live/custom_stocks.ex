defmodule LivePubDemoWeb.CustomStockList do
  use LivePubDemoWeb, :live_view

  alias Phoenix.PubSub

  require Logger

  @pubsub_name Trading.PubSub
  @pubsub_topic_common "trading:common"
  @pubsub_topic_stock_prefix "stock:"

  def mount(params, session, socket) do
    PubSub.broadcast(@pubsub_name, @pubsub_topic_common, {:join,  Map.get(session, "session_id"), []})

    socket =
      socket
      |> assign(:stocks, %{})
      |> assign(:counter, 0)
      |> assign(:total, 0)

    {:ok, socket}
  end

  def render(assigns) do
   ~H"""
    <section class="phx-hero">
    <h1>List of stocks (custom list, total: <%= @total %>)</h1>
    <table>
        <tr>
            <td>Stock</td>
            <td>Price</td>
            <td>Time</td>
        </tr>
        <%= for {_, stock} <- @stocks do %>
            <tr>
                <td><p style={stock.color}><%= stock.stock_name %></p></td>
                <td><p style={stock.color}><%= stock.stock_price %></p></td>
                <td><%= stock.update_at %></td>
            </tr>
        <% end %>
    </table>
    <p>Update Counter: <%= @counter %></p>
    <form phx-change="add_stock">
       <input name="stock" phx-debounce="30" value="" />
    </form>
    </section>
    """
  end

  def handle_info({:update_price, {stock_name, price, time}}, socket) do
    #Logger.info("update stock price, id: #{stock_name}")

    # build new stock for cached
    stock = %{stock_name: stock_name, stock_price: price, update_at: time}

    stocks = socket.assigns.stocks
    stocks =
      if Map.has_key?(stocks, stock_name) do
        Map.update!(stocks, stock_name,
        fn old ->
          color =
            cond do
              old.stock_price < price ->
                "color: blue"
              old.stock_price > price ->
                "color: red"
              true ->
                "color: black"
            end

          stock
          |> Map.put(:stock_price, price)
          |> Map.put(:update_at, time)
          |> Map.put(:color, color)
        end)
      else
        stocks
      end

    socket =  assign(socket, :stocks, stocks)

    {:noreply, update(socket, :counter, &(&1 + 1))}
  end

  def handle_info({:add_stock, stock_name}, socket) do
    Logger.info("update stock price, id: #{stock_name}")

    # build new stock for cached
    stock = %{stock_name: stock_name, stock_price: "N/A", update_at: "N/A"}

    PubSub.subscribe(@pubsub_name, @pubsub_topic_stock_prefix <> stock_name)

    {:noreply, assign(socket, :stocks, Map.put(socket.assigns, stock_name, stock))}
  end

  def handle_event("add_stock", %{"stock" => value},  socket) do
    Logger.debug("add event, value: #{inspect value}")
    new_list = String.split(value)
    current_stocks = socket.assigns.stocks

    updated_stocks = update_stocks(new_list, current_stocks)

    {:noreply, assign(socket, :stocks, updated_stocks)}
  end

  defp update_stocks(list, stocks) when is_map(stocks) and is_list(list) do
    update_stocks(list, stocks, %{})
  end

  defp update_stocks([], _stocks, new_stocks) do
    new_stocks
  end

  defp update_stocks([name | rest], stocks, new_stocks) do
    name = String.trim(name)
    stock =
      case Map.get(stocks, name, :not_found) do
        :not_found ->
          if validate_name?(name) do
            # subscribe stock for get & listening price changing
            PubSub.subscribe(@pubsub_name, @pubsub_topic_stock_prefix <> name)
            Logger.info("subscribed for #{name}")
          end

          %{}
          |> Map.put_new(:stock_name, name)
          |> Map.put_new(:stock_price, "N/A")
          |> Map.put_new(:update_at, "N/A")
          |> Map.put_new(:color, "color: black")

        s ->
          s
      end

    update_stocks(rest, stocks, Map.put(new_stocks, name, stock))
  end

  # just simple verification function for check valid stock name
  defp validate_name?("stock_" <> str) when str != "" do
    case Integer.parse(str) do
      {n, _} when n > 0 and n < 10001->
        true
      _ ->
        false
    end
  end
  defp validate_name?(_) do
    false
  end
end
