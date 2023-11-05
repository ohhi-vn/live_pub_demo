defmodule LivePubDemo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      LivePubDemoWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: LivePubDemo.PubSub},
      # Start the Endpoint (http/https)
      LivePubDemoWeb.Endpoint,

      # For internal pubsub
      Supervisor.child_spec({Phoenix.PubSub, name: Trading.PubSub}, id: Trading.InternalPubSub),

      # Start a worker by calling: LivePubDemo.Worker.start_link(arg)
      # {LivePubDemo.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LivePubDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LivePubDemoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
