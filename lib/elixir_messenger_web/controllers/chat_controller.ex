defmodule ElixirMessengerWeb.ChatController do
  use ElixirMessengerWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end
end
