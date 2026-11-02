defmodule ElixirMessengerWeb.ChatControllerTest do
  use ElixirMessengerWeb.ConnCase

  alias ElixirMessenger.Users
  alias ElixirMessenger.Users.User

  setup do
    :ets.delete_all_objects(:users)
    :ets.delete_all_objects(:users_by_name)
    :ok
  end

  test "redirects guests to the login page", %{conn: conn} do
    conn = get(conn, ~p"/")

    assert redirected_to(conn) == ~p"/login"
    assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "log in"
  end

  test "renders the empty chat shell for logged-in users", %{conn: conn} do
    {:ok, user} = Users.insert(%User{name: "alice", password: "secret"})

    conn =
      conn
      |> init_test_session(%{"user_token" => ElixirMessengerWeb.Auth.sign(user)})
      |> get(~p"/")

    assert html_response(conn, 200) =~ "alice"
    assert conn.resp_body =~ "Log out"
    assert conn.resp_body =~ "Your messages will appear here"
  end
end
