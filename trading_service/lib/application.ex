defmodule Trading.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: Trading.PubSub},
      {Trading.Simulator, []},
      {Trading.StockDelivery, []}
    ]

    opts = [
      strategy: :one_for_one,
      name: Trading.Supervisor
    ]

    Supervisor.start_link(children, opts)
  end
end
