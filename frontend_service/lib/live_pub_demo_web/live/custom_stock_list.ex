defmodule LivePubDemoWeb.CustomStockList do
  use LivePubDemoWeb, :live_view

  alias Phoenix.PubSub

  require Logger

  @pubsub_name Trading.PubSub
  @pubsub_topic_common "trading:common"
  @pubsub_topic_stock_prefix "stock:"

  ### Callbacks ###

  @impl true
  def mount(params, session, socket) do
    #:dbg.p(self(), :m)
    session_id = Map.get(session, "session_id")
    PubSub.broadcast(@pubsub_name, @pubsub_topic_common, {:join,  session_id, []})

    socket =
      socket
      |> stream(:stocks, [])
      |> assign(:counter, 0)
      |> assign(:total, 0)
      |> assign(:page_title, "Custom Stock List")
      |> assign(:session_id, session_id)
      |> assign(:cached, %{})

    fields = %{"list_stock" => ""}
    socket = assign(socket, form: to_form(fields))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
   ~H"""
    <section class="phx-hero">
    <div class="flex-row">
    <div>
    <p class="text-xl font-bold">List of stocks (custom list, total: <%= @total %>)</p>
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

    <.form
      for={@form}
      phx-change="add_stock"
    >
      <.input_stocks field={@form[:list_stock]} />
    </.form>
    </div>

    </section>
    """
  end

  @impl true
  def handle_info({:update_price, {stock_name, price, time}}, socket) do
    #Logger.info("update stock price, id: #{stock_name}")

    # build new stock for cached
    stock = %{id: stock_name, stock_name: stock_name, stock_price: price, update_at: time}

    cached =
      socket.assigns.cached
      |> Enum.reduce(%{}, fn {k, v}, acc ->
          v = Map.put(v, :changed, false)
          Map.put(acc, k, v)
        end)
    cached =
      if Map.has_key?(cached, stock_name) do
        Map.update!(cached, stock_name,
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
          changed = old.stock_price != price

          stock
          |> Map.put(:stock_price, price)
          |> Map.put(:update_at, time)
          |> Map.put(:color, color)
          |> Map.put(:changed, changed)
        end)
      else
        cached
      end

    updated_stock =
      cached
      |> Enum.filter(fn {_k, v} ->
          v.changed
      end)
      |> Enum.map(fn {_k, v} -> v end)

    socket =
      updated_stock
      |> Enum.reduce(socket, fn stock, acc ->
        acc
        |> stream_insert(:stocks, stock)
      end)

    socket =
      socket
      |> assign(:cached, cached)
      |> update(:counter, &(&1 + 1))

    {:noreply, socket}
  end

  @impl true
  def handle_info({:add_stock, stock_name}, socket) do
    Logger.info("update stock price, id: #{stock_name}")

    # build new stock for cached
    stock = %{id: stock_name, stock_name: stock_name, stock_price: "N/A", update_at: "N/A"}

    PubSub.subscribe(@pubsub_name, @pubsub_topic_stock_prefix <> stock_name)

    socket =
      socket
      |> stream_insert(socket, :stocks, [stock])
      |> assign(:cached, Map.put(socket.assigns.cached, stock_name, stock))

    {:noreply, socket}
  end

  @impl true
  def handle_event("add_stock", %{"list_stock" => value},  socket) do
    Logger.debug("add event, value: #{inspect value}")
    new_list = String.split(value)
    current_stocks = socket.assigns.cached

    {updated_stocks, ignore_stocks} = update_stocks(new_list, current_stocks)

    Logger.debug("updated_stocks: #{inspect updated_stocks}, \nignore_stocks: #{inspect ignore_stocks}")

    fields = %{"list_stock" => value}

    socket =
      updated_stocks
      |> Enum.filter(fn {_k, v} -> v.new end)
      |> Enum.map(fn {_k, v} -> v end)
      |> Enum.reduce(socket, fn stock, acc ->
        acc
        |> stream_insert(:stocks, stock)
      end)


    socket = Enum.reduce(ignore_stocks, socket, fn {_, stock}, acc ->
      acc
      |> stream_delete(:stocks, stock)
    end)

    socket =
      socket
      |> assign(:cached, updated_stocks)
      |> assign(:total, map_size(updated_stocks))
      |> assign(:page_title, "Custom Stock List (#{map_size(updated_stocks)})")
      |> assign(form: to_form(fields))

    {:noreply, socket}
  end

  @impl true
  def terminate(reason, socket) do
    Logger.info("session: #{socket.assigns.session_id}, terminate: #{inspect reason}")

    for stock_name <- Map.keys(socket.assigns.cached) do
      PubSub.unsubscribe(@pubsub_name, @pubsub_topic_stock_prefix <> stock_name)
    end

    socket
  end

  ### Public functions ###

  def input_stocks(assigns) do
    ~H"""
    <input type="text" name={@field.name} id={@field.id} value={@field.value} placeholder="Add stock here, seperated by space" />
    """
  end


  ### Private functions ###

  defp update_stocks(new_list, current_stocks) when is_map(current_stocks) and is_list(new_list) do
    update_stocks(new_list, current_stocks, %{})
  end

  defp update_stocks([], current_stocks, new_stocks) do
    # unsubscribe stocks not in new list
    for stock_name <- Map.keys(current_stocks), !Map.has_key?(new_stocks, stock_name) do
      PubSub.unsubscribe(@pubsub_name, @pubsub_topic_stock_prefix <> stock_name)
    end

    {new_stocks, current_stocks}
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
          |> Map.put_new(:id, name)
          |> Map.put_new(:new, true)

        s ->
          Map.put(s, :new, false)
      end

    update_stocks(rest, Map.delete(stocks, name), Map.put(new_stocks, name, stock))
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
