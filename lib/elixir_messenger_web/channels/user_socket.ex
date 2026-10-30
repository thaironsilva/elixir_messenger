defmodule ElixirMessengerWeb.UserSocket do
  use Phoenix.Socket

  alias ElixirMessengerWeb.Auth

  ## Channels

  channel "chat_room:*", ElixirMessengerWeb.ChatRoomChannel

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case Auth.verify(token) do
      {:ok, user} -> {:ok, assign(socket, :current_user, user)}
      :error -> :error
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.current_user.id}"
end
