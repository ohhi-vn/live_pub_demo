defmodule LivePubDemoWeb.Stocks do
  use LivePubDemoWeb, :live_view

  def mount(params, _session, socket) do
    num =
      Map.get(params, "num", "1")
      |> String.to_integer()

    stocks = gen_stock(num)
    socket =
      socket
      |> assign(:stocks, stocks)
      |> assign(:num, num)

    {:ok, socket}
  end

  def render(assigns) do
   ~H"""
    <section class="phx-hero">
    <h1>List of stocks (total: <%= @num %>)</h1>
    <table>
        <tr>
            <td>Stock</td>
            <td>Price</td>
            <td>Time</td>
        </tr>
        <%= for {_, stock} <- @stocks do %>
            <tr>
                <td><%= stock.stock_name %></td>
                <td><%= stock.stock_price %></td>
                <td><%= stock.update_at %></td>
            </tr>
        <% end %>
    </table>
    </section>
    """
  end

  defp gen_stock(num) do
    gen_stock(num, %{})
  end

  defp gen_stock(0, stocks) do
    stocks
  end

  defp gen_stock(num, stocks) do
    name = "Stock_#{num}"
    stock =
    %{}
    |> Map.put_new(:stock_name, name)
    |> Map.put_new(:stock_price, "N/A")
    |> Map.put_new(:update_at, "N/A")

    gen_stock(num - 1, Map.put_new(stocks, name, stock))
  end
end
