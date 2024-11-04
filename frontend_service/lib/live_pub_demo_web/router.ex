defmodule LivePubDemoWeb.Router do
  use LivePubDemoWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {LivePubDemoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :assign_session_id
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LivePubDemoWeb do
    pipe_through :browser

    get "/", PageController, :home

    live "/dynamic_list", DynamicStockList
    live "/fix_list", FixStockList
    live "/simple_list", SimpleStockList
    live "/custom_list", CustomStockList
  end


  defp assign_session_id(conn, _) do
    if get_session(conn, :session_id) do
      conn
    else
      session_id = UUID.uuid1()
      conn
      |> put_session(:session_id, session_id)
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", LivePubDemoWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: LivePubDemoWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser
    end
  end
end
