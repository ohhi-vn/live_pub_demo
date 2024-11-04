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
    <div class="flex-row">
    <div>
    <p class="text-xl font-bold">List of stocks (fixed list)</p>
    </div>

    <div class="grid gird-cols-5 sx:grid-cols-3 sm:grid-cols-3 md:grid-cols-5 xl:grid-cols-6 p-1  space-y-3 space-x-3" id="stocks">
        <.live_component module={LivePubDemoWeb.StockItemCard} id={@stock_1.stock_name} stock={@stock_1} />
        <.live_component module={LivePubDemoWeb.StockItemCard} id={@stock_2.stock_name} stock={@stock_2} />
        <.live_component module={LivePubDemoWeb.StockItemCard} id={@stock_3.stock_name} stock={@stock_3} />
        <.live_component module={LivePubDemoWeb.StockItemCard} id={@stock_4.stock_name} stock={@stock_4} />
        <.live_component module={LivePubDemoWeb.StockItemCard} id={@stock_5.stock_name} stock={@stock_5} />
        <.live_component module={LivePubDemoWeb.StockItemCard} id={@stock_6.stock_name} stock={@stock_6} />
        <.live_component module={LivePubDemoWeb.StockItemCard} id={@stock_7.stock_name} stock={@stock_7} />
        <.live_component module={LivePubDemoWeb.StockItemCard} id={@stock_8.stock_name} stock={@stock_8} />
        <.live_component module={LivePubDemoWeb.StockItemCard} id={@stock_9.stock_name} stock={@stock_9} />
        <.live_component module={LivePubDemoWeb.StockItemCard} id={@stock_10.stock_name} stock={@stock_10} />
        <.live_component module={LivePubDemoWeb.StockItemCard} id={@stock_11.stock_name} stock={@stock_11} />
        <.live_component module={LivePubDemoWeb.StockItemCard} id={@stock_12.stock_name} stock={@stock_12} />
        <.live_component module={LivePubDemoWeb.StockItemCard} id={@stock_13.stock_name} stock={@stock_13} />
        <.live_component module={LivePubDemoWeb.StockItemCard} id={@stock_14.stock_name} stock={@stock_14} />
        <.live_component module={LivePubDemoWeb.StockItemCard} id={@stock_15.stock_name} stock={@stock_15} />
        <.live_component module={LivePubDemoWeb.StockItemCard} id={@stock_16.stock_name} stock={@stock_16} />
        <.live_component module={LivePubDemoWeb.StockItemCard} id={@stock_17.stock_name} stock={@stock_17} />
        <.live_component module={LivePubDemoWeb.StockItemCard} id={@stock_18.stock_name} stock={@stock_18} />
        <.live_component module={LivePubDemoWeb.StockItemCard} id={@stock_19.stock_name} stock={@stock_19} />
        <.live_component module={LivePubDemoWeb.StockItemCard} id={@stock_20.stock_name} stock={@stock_20} />
        <.live_component module={LivePubDemoWeb.StockItemCard} id={@stock_21.stock_name} stock={@stock_21} />
        <.live_component module={LivePubDemoWeb.StockItemCard} id={@stock_22.stock_name} stock={@stock_22} />
        <.live_component module={LivePubDemoWeb.StockItemCard} id={@stock_23.stock_name} stock={@stock_23} />
        <.live_component module={LivePubDemoWeb.StockItemCard} id={@stock_24.stock_name} stock={@stock_24} />
        <.live_component module={LivePubDemoWeb.StockItemCard} id={@stock_25.stock_name} stock={@stock_25} />
        <.live_component module={LivePubDemoWeb.StockItemCard} id={@stock_26.stock_name} stock={@stock_26} />
        <.live_component module={LivePubDemoWeb.StockItemCard} id={@stock_27.stock_name} stock={@stock_27} />
        <.live_component module={LivePubDemoWeb.StockItemCard} id={@stock_28.stock_name} stock={@stock_28} />
        <.live_component module={LivePubDemoWeb.StockItemCard} id={@stock_29.stock_name} stock={@stock_29} />
        <.live_component module={LivePubDemoWeb.StockItemCard} id={@stock_30.stock_name} stock={@stock_30} />
    </div>
    <div class="px-5 py-5">
      <p class="text-l font-bold">Update Counter: <%= @counter %></p>
    </div>
    </div>
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
    gen_stock(1, 30, socket, [])
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
