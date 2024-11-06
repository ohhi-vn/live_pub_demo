defmodule LivePubDemoWeb.SimpleStockList do
  use LivePubDemoWeb, :live_view

  alias Phoenix.PubSub

  require Logger

  @pubsub_name Trading.PubSub
  @pubsub_topic_common "trading:common"
  @pubsub_topic_stock_prefix "stock:"


  ### Callbacks ###

  @impl true
  def mount(_params, session, socket) do
    IO.inspect(self(), label: "MOUNT_EVENT")

    # debug info
    # :dbg.tracer()
    # :dbg.p(self(), [:m])

    session_id = Map.get(session, "session_id")

    {socket, stock_names} = gen_stock(socket)

    PubSub.broadcast(@pubsub_name, @pubsub_topic_common, {:join, session_id, stock_names})

    socket =
      socket
      |> assign(:page_title, "Simple Stock List (#{length(stock_names)})")
      |> assign(:counter, 0)
      |> assign(:session_id, session_id)
      |> assign(:stock_list, stock_names)

    {:ok,  socket}
  end

  @impl true
  def render(assigns) do
    IO.inspect(self(), label: "RENDER_EVENT")

    ~H"""
    <section class="phx-hero">
    <div class="flex-row">
      <div>
        <p class="text-xl font-bold">List of stocks (Simple list)</p>
      </div>

      <div class="flex-row p-1  space-y-3 space-x-3">
        <div class="container max-w-md rounded overflow-hidden shadow-lg bg-gray-300">
          <div class="px-2 py-2" >
            <div class="font-bold text-xl mb-2"><%= @stock_1.stock_name %></div>
            <div class="flex flex-col text-sm text-gray-600 italic">
            <div class="" style={@stock_1.color}> Price: <%= @stock_1.stock_price %></div>
            </div>
          </div>
        </div>
        </div>

        <div class="container max-w-md rounded overflow-hidden shadow-lg bg-gray-300">
          <div class="px-2 py-2" >
            <div class="font-bold text-xl mb-2"><%= @stock_2.stock_name %></div>
            <div class="flex flex-col text-sm text-gray-600 italic">
            <div class="" style={@stock_2.color}> Price: <%= @stock_2.stock_price %></div>
            </div>
          </div>
        </div>

    <div class="px-1 py-5">
      <p class="text-l font-bold">Update Counter: <%= @counter %></p>
    </div>
    </div>
    </section>
    """
  end

  @impl true
  def handle_info({:update_price, {stock_name, price, time}}, socket) do
    IO.inspect(self(), label: "HANDLE_INFO_EVENT")

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
    IO.inspect(self(), label: "TERMINATE_EVENT")

    :dbg.stop()

    Logger.info("session: #{socket.assigns.session_id}, terminate: #{inspect reason}")

    for stock_name <- socket.assigns.stock_list do
      PubSub.unsubscribe(@pubsub_name, @pubsub_topic_stock_prefix <> stock_name)
    end

    socket
  end

  defp gen_stock(socket) do
    gen_stock(1, 2, socket, [])
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
