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
        <.live_component module={LivePubDemoWeb.StockItem} id={@stock_1.stock_name} stock={@stock_1} />
        <.live_component module={LivePubDemoWeb.StockItem} id={@stock_2.stock_name} stock={@stock_2} />
        <.live_component module={LivePubDemoWeb.StockItem} id={@stock_3.stock_name} stock={@stock_3} />
        <.live_component module={LivePubDemoWeb.StockItem} id={@stock_4.stock_name} stock={@stock_4} />
        <.live_component module={LivePubDemoWeb.StockItem} id={@stock_5.stock_name} stock={@stock_5} />
        <.live_component module={LivePubDemoWeb.StockItem} id={@stock_6.stock_name} stock={@stock_6} />
        <.live_component module={LivePubDemoWeb.StockItem} id={@stock_7.stock_name} stock={@stock_7} />
        <.live_component module={LivePubDemoWeb.StockItem} id={@stock_8.stock_name} stock={@stock_8} />
        <.live_component module={LivePubDemoWeb.StockItem} id={@stock_9.stock_name} stock={@stock_9} />
        <.live_component module={LivePubDemoWeb.StockItem} id={@stock_10.stock_name} stock={@stock_10} />
        <.live_component module={LivePubDemoWeb.StockItem} id={@stock_11.stock_name} stock={@stock_11} />
        <.live_component module={LivePubDemoWeb.StockItem} id={@stock_12.stock_name} stock={@stock_12} />
        <.live_component module={LivePubDemoWeb.StockItem} id={@stock_13.stock_name} stock={@stock_13} />
        <.live_component module={LivePubDemoWeb.StockItem} id={@stock_14.stock_name} stock={@stock_14} />
        <.live_component module={LivePubDemoWeb.StockItem} id={@stock_15.stock_name} stock={@stock_15} />
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
    gen_stock(1, 15, socket, [])
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
