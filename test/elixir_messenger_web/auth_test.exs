defmodule ElixirMessengerWeb.AuthTest do
  use ExUnit.Case, async: false

  alias ElixirMessenger.Users
  alias ElixirMessenger.Users.User
  alias ElixirMessengerWeb.Auth

  setup do
    :ets.delete_all_objects(:users)
    :ets.delete_all_objects(:users_by_name)
    :ok
  end

  test "sign/1 and verify/1 round-trip a user" do
    {:ok, user} = Users.insert(%User{name: "alice", password: "secret"})

    assert {:ok, %User{id: id}} = user |> Auth.sign() |> Auth.verify()
    assert id == user.id
  end

  test "verify/1 rejects missing, malformed and tampered tokens" do
    {:ok, user} = Users.insert(%User{name: "alice", password: "secret"})
    token = Auth.sign(user)

    tampered = String.slice(token, 0..-2//1) <> if(String.last(token) == "a", do: "b", else: "a")

    assert :error = Auth.verify(nil)
    assert :error = Auth.verify("not-a-token")
    assert :error = Auth.verify(tampered)
  end
end
