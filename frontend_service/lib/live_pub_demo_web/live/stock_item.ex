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
