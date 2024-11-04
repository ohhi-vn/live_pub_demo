defmodule LivePubDemoWeb.StockItem do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <tr>
      <td><p style={@stock.color}><%= @stock.stock_name %></p></td>
      <td><p style={@stock.color}><%= @stock.stock_price %></p></td>
      <td><%= @stock.update_at %></td>
    </tr>
    """
  end

  def update_many(assigns_sockets) do
    Enum.map(assigns_sockets, fn {assigns, socket} ->
      assign(socket, :stock, assigns.stock)
    end)
  end
end

defmodule LivePubDemoWeb.StockItemCard do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <div class="container max-w-md rounded overflow-hidden shadow-lg bg-gray-300">
      <div class="px-2 py-2" >
          <div class="font-bold text-xl mb-2"><%= @stock.stock_name %></div>
          <div class="flex flex-col text-sm text-gray-600 italic">
          <div class="" style={@stock.color}> Price: <%= @stock.stock_price %></div>
          <div class=""> Update:
          <%= if @stock.update_at == "N/A" do %>
            <%= "N/A" %>
          <% else %>
           <%= NaiveDateTime.to_time(@stock.update_at) %>
          <% end %>
          </div>
        </div>
      </div>
      <div class="px-6 pt-4 pb-2">
      </div>
      </div>
    """
  end

  def update_many(assigns_sockets) do
    Enum.map(assigns_sockets, fn {assigns, socket} ->
      assign(socket, :stock, assigns.stock)
    end)
  end
end
