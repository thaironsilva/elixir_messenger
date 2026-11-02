defmodule ElixirMessengerWeb.ChatRoomChannelTest do
  use ElixirMessengerWeb.ChannelCase

  alias ElixirMessenger.Users
  alias ElixirMessenger.Users.User

  setup do
    :ets.delete_all_objects(:users)
    :ets.delete_all_objects(:users_by_name)
    {:ok, user} = Users.insert(%User{name: "alice", password: "secret"})
    %{user: user}
  end

  test "joined users can ping, shout and receive broadcasts", %{user: user} do
    {:ok, _, socket} =
      ElixirMessengerWeb.UserSocket
      |> socket("user_id", %{current_user: user})
      |> subscribe_and_join(ElixirMessengerWeb.ChatRoomChannel, "chat_room:lobby")

    ref = push(socket, "ping", %{"hello" => "there"})
    assert_reply ref, :ok, %{"hello" => "there"}

    push(socket, "shout", %{"hello" => "all"})
    assert_broadcast "shout", %{"hello" => "all"}

    broadcast_from!(socket, "broadcast", %{"some" => "data"})
    assert_push "broadcast", %{"some" => "data"}
  end

  test "rejects anonymous joins" do
    assert {:error, %{reason: "unauthorized"}} =
             ElixirMessengerWeb.UserSocket
             |> socket("user_id", %{})
             |> subscribe_and_join(ElixirMessengerWeb.ChatRoomChannel, "chat_room:lobby")
  end
end
