defmodule LivePubDemoWeb.FixStockList do
  use LivePubDemoWeb, :live_view

  alias Phoenix.PubSub

  require Logger

  @pubsub_name Trading.PubSub
  @pubsub_topic_common "trading:common"
  @pubsub_topic_stock_prefix "stock:"


  ### Callbacks ###

  def mount(_params, session, socket) do
    session_id = Map.get(session, "session_id")

    {socket, stock_names} = gen_stock(socket)

    PubSub.broadcast(@pubsub_name, @pubsub_topic_common, {:join, session_id, stock_names})

    socket =
      socket
      |> assign(:page_title, "Fixed Stock List (#{length(stock_names)})")
      |> assign(:counter, 0)
      |> assign(:session_id, session_id)
      |> assign(:stock_list, stock_names)

    {:ok,  socket}
  end

  def render(assigns) do
   ~H"""
    <section class="phx-hero">
    <h1>List of stocks (fixed list)</h1>
    <table>
        <tr>
            <td>Stock</td>
            <td>Price</td>
            <td>Time</td>
        </tr>
        <tr>
            <td><p style={@stock_1.color}><%= @stock_1.stock_name %></p></td>
            <td><p style={@stock_1.color}><%= @stock_1.stock_price %></p></td>
            <td><%= @stock_1.update_at %></td>
        </tr>
        <tr>
            <td><p style={@stock_2.color}><%= @stock_2.stock_name %></p></td>
            <td><p style={@stock_2.color}><%= @stock_2.stock_price %></p></td>
            <td><%= @stock_2.update_at %></td>
        </tr>
        <tr>
            <td><p style={@stock_3.color}><%= @stock_3.stock_name %></p></td>
            <td><p style={@stock_3.color}><%= @stock_3.stock_price %></p></td>
            <td><%= @stock_3.update_at %></td>
        </tr>
        <tr>
            <td><p style={@stock_4.color}><%= @stock_4.stock_name %></p></td>
            <td><p style={@stock_4.color}><%= @stock_4.stock_price %></p></td>
            <td><%= @stock_4.update_at %></td>
        </tr>
        <tr>
            <td><p style={@stock_5.color}><%= @stock_5.stock_name %></p></td>
            <td><p style={@stock_5.color}><%= @stock_5.stock_price %></p></td>
            <td><%= @stock_5.update_at %></td>
        </tr>
        <tr>
            <td><p style={@stock_6.color}><%= @stock_6.stock_name %></p></td>
            <td><p style={@stock_6.color}><%= @stock_6.stock_price %></p></td>
            <td><%= @stock_6.update_at %></td>
        </tr>
        <tr>
            <td><p style={@stock_7.color}><%= @stock_7.stock_name %></p></td>
            <td><p style={@stock_7.color}><%= @stock_7.stock_price %></p></td>
            <td><%= @stock_7.update_at %></td>
        </tr>
        <tr>
            <td><p style={@stock_8.color}><%= @stock_8.stock_name %></p></td>
            <td><p style={@stock_8.color}><%= @stock_8.stock_price %></p></td>
            <td><%= @stock_8.update_at %></td>
        </tr>
        <tr>
            <td><p style={@stock_9.color}><%= @stock_9.stock_name %></p></td>
            <td><p style={@stock_9.color}><%= @stock_9.stock_price %></p></td>
            <td><%= @stock_9.update_at %></td>
        </tr>
        <tr>
            <td><p style={@stock_10.color}><%= @stock_10.stock_name %></p></td>
            <td><p style={@stock_10.color}><%= @stock_10.stock_price %></p></td>
            <td><%= @stock_10.update_at %></td>
        </tr>
    </table>
    <p>Update Counter: <%= @counter %></p>
    </section>
    """
  end

  def handle_info({:update_price, {stock_name, price, time}}, socket) do
    #Logger.info("update stock price, id: #{stock_name}")

    # build new stock for cached
    stock = %{stock_name: stock_name, stock_price: price, update_at: time}

    socket = update(socket, String.to_atom(stock_name),
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

    {:noreply, update(socket, :counter, &(&1 + 1))}
  end

  @impl true
  def terminate(reason, socket) do
    Logger.info("session: #{socket.assigns.session_id}, terminate: #{inspect reason}")

    for stock_name <- socket.assigns.stock_list do
      PubSub.unsubscribe(@pubsub_name, @pubsub_topic_stock_prefix <> stock_name)
    end

    socket
  end

  ### Private functions ###

  defp gen_stock(socket) do
    gen_stock(1, 10, socket, [])
  end

  defp gen_stock(from, to, socket, stock_names) when from > to do
    {socket, stock_names}
  end

  defp gen_stock(from, to, socket, stock_names) do
    name = "stock_#{from}"
    stock =
      %{}
      |> Map.put_new(:stock_name, name)
      |> Map.put_new(:stock_price, "N/A")
      |> Map.put_new(:update_at, "N/A")
      |> Map.put_new(:color, "color: black")

    # subscribe stock for listening price changing
    PubSub.subscribe(@pubsub_name, @pubsub_topic_stock_prefix <> name)

    gen_stock(from + 1, to, assign(socket, String.to_atom(name), stock), [name | stock_names])
  end
end
