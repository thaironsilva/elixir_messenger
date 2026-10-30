defmodule ElixirMessengerWeb.UserSocketTest do
  use ExUnit.Case, async: false

  alias ElixirMessenger.Users
  alias ElixirMessenger.Users.User
  alias ElixirMessengerWeb.Auth
  alias ElixirMessengerWeb.UserSocket

  setup do
    :ets.delete_all_objects(:users)
    :ets.delete_all_objects(:users_by_name)
    {:ok, user} = Users.insert(%User{name: "alice", password: "secret"})
    %{user: user}
  end

  test "connects users with a valid token", %{user: user} do
    assert {:ok, socket} = UserSocket.connect(%{"token" => Auth.sign(user)}, socket(), %{})
    assert socket.assigns.current_user.id == user.id
  end

  test "rejects missing, malformed and unknown-user tokens" do
    assert :error = UserSocket.connect(%{}, socket(), %{})
    assert :error = UserSocket.connect(%{"token" => "garbage"}, socket(), %{})

    {:ok, deleted_user} = Users.insert(%User{name: "gone", password: "secret"})
    :ok = Users.delete(deleted_user.id)

    assert :error =
             UserSocket.connect(%{"token" => Auth.sign(deleted_user)}, socket(), %{})
  end

  defp socket, do: %Phoenix.Socket{handler: UserSocket}
end
