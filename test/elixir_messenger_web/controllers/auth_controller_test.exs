defmodule ElixirMessengerWeb.AuthControllerTest do
  use ElixirMessengerWeb.ConnCase

  alias ElixirMessenger.Users
  alias ElixirMessenger.Users.User

  setup do
    :ets.delete_all_objects(:users)
    :ets.delete_all_objects(:users_by_name)
    :ok
  end

  describe "the shared auth card" do
    test "renders login for guests and signup with the confirmation field", %{conn: conn} do
      login = get(conn, ~p"/login")
      assert html_response(login, 200) =~ "Log in"
      assert login.resp_body =~ ~s(name="user[password]")

      signup = get(build_conn(), ~p"/signup")
      assert html_response(signup, 200) =~ "Sign up"
      assert signup.resp_body =~ ~s(name="user[password_confirmation]")
    end

    test "redirects authenticated users away from login and signup", %{conn: conn} do
      user = insert_user("alice")

      assert redirected_to(get(log_in(conn, user), ~p"/login")) == ~p"/"
      assert redirected_to(get(log_in(build_conn(), user), ~p"/signup")) == ~p"/"
    end
  end

  describe "login" do
    test "logs an existing user in and lands them in the chat", %{conn: conn} do
      insert_user("alice", "secret")

      conn =
        post(conn, ~p"/login", %{
          "user" => %{"name" => "alice", "password" => "secret"}
        })

      assert redirected_to(conn) == ~p"/"

      chat = get(recycle(conn), ~p"/")
      assert html_response(chat, 200) =~ "alice"
      assert chat.resp_body =~ "Log out"
    end

    test "rejects wrong, unknown and blank credentials with a generic error", %{conn: conn} do
      insert_user("alice", "secret")

      responses = [
        post(conn, ~p"/login", %{"user" => %{"name" => "alice", "password" => "wrong"}}),
        post(build_conn(), ~p"/login", %{"user" => %{"name" => "bob", "password" => "secret"}}),
        post(build_conn(), ~p"/login", %{"user" => %{"name" => "alice", "password" => ""}})
      ]

      for response <- responses do
        assert html_response(response, 200) =~ "Invalid name or password"
      end
    end
  end

  describe "signup and logout" do
    test "signs up, enters the chat and logs out", %{conn: conn} do
      conn =
        post(conn, ~p"/signup", %{
          "user" => %{
            "name" => "alice",
            "password" => "secret",
            "password_confirmation" => "secret"
          }
        })

      assert redirected_to(conn) == ~p"/"
      assert {:ok, user} = Users.get_by_name("alice")
      refute user.password == "secret"

      chat = get(recycle(conn), ~p"/")
      assert html_response(chat, 200) =~ "alice"
      assert chat.resp_body =~ "Log out"

      logged_out = delete(recycle(chat), ~p"/logout")
      assert redirected_to(logged_out) == ~p"/login"
      assert redirected_to(get(recycle(logged_out), ~p"/")) == ~p"/login"
    end

    test "shows validation errors and never creates the user", %{conn: conn} do
      insert_user("taken")

      invalid_payloads = [
        {%{"name" => "", "password" => "secret", "password_confirmation" => "secret"},
         "Name is required"},
        {%{"name" => "bob", "password" => "", "password_confirmation" => ""},
         "Password is required"},
        {%{"name" => "bob", "password" => "secret", "password_confirmation" => "other"},
         "Passwords do not match"},
        {%{"name" => "taken", "password" => "secret", "password_confirmation" => "secret"},
         "Name has already been taken"}
      ]

      for {params, message} <- invalid_payloads do
        response = post(conn, ~p"/signup", %{"user" => params})
        assert html_response(response, 200) =~ message
      end

      assert Users.get_by_name("bob") == {:error, :not_found}
    end
  end

  defp insert_user(name, password \\ "secret") do
    {:ok, user} = Users.insert(%User{name: name, password: password})
    user
  end

  defp log_in(conn, user) do
    init_test_session(conn, %{"user_token" => ElixirMessengerWeb.Auth.sign(user)})
  end
end
