defmodule LivePubDemoWeb.PageController do
  use LivePubDemoWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
