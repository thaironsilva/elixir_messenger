defmodule ElixirMessengerWeb.AuthController do
  use ElixirMessengerWeb, :controller

  alias ElixirMessenger.Users
  alias ElixirMessenger.Users.Password
  alias ElixirMessenger.Users.User
  alias ElixirMessengerWeb.Auth

  def login(conn, _params) do
    render(conn, :auth, mode: :login, name: "", layout: false)
  end

  def signup(conn, _params) do
    render(conn, :auth, mode: :signup, name: "", layout: false)
  end

  def create_login(conn, %{"user" => %{"name" => name, "password" => password}}) do
    with {:ok, user} <- Users.get_by_name(name),
         true <- Password.matches?(password, user.password) do
      conn
      |> Auth.log_in(user)
      |> put_flash(:info, "Welcome back, #{user.name}!")
      |> redirect(to: ~p"/")
    else
      _ ->
        conn
        |> put_flash(:error, "Invalid name or password")
        |> render(:auth, mode: :login, name: name, layout: false)
    end
  end

  def create_login(conn, _params) do
    conn
    |> put_flash(:error, "Invalid name or password")
    |> render(:auth, mode: :login, name: "", layout: false)
  end

  def create_signup(conn, %{"user" => params}) do
    name = params["name"] || ""
    password = params["password"] || ""
    confirmation = params["password_confirmation"] || ""

    with :ok <- User.validate_registration(name, password, confirmation),
         {:ok, user} <- Users.insert(%User{name: name, password: password}) do
      conn
      |> Auth.log_in(user)
      |> put_flash(:info, "Welcome, #{user.name}!")
      |> redirect(to: ~p"/")
    else
      {:error, reason} ->
        conn
        |> put_flash(:error, registration_error(reason))
        |> render(:auth, mode: :signup, name: name, layout: false)
    end
  end

  def create_signup(conn, _params) do
    conn
    |> put_flash(:error, "Name is required")
    |> render(:auth, mode: :signup, name: "", layout: false)
  end

  def delete(conn, _params) do
    conn
    |> Auth.log_out()
    |> put_flash(:info, "You have been logged out.")
    |> redirect(to: ~p"/login")
  end

  defp registration_error(:name_required), do: "Name is required"
  defp registration_error(:password_required), do: "Password is required"
  defp registration_error(:password_mismatch), do: "Passwords do not match"
  defp registration_error(:already_exists), do: "Name has already been taken"
end
