defmodule ElixirMessengerWeb.Auth do
  @moduledoc """
  Token based authentication shared by controllers and sockets.
  """

  import Plug.Conn
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]

  alias ElixirMessenger.Users
  alias ElixirMessengerWeb.Endpoint

  @salt "user auth"
  @max_age 60 * 60 * 24 * 14
  @session_key "user_token"

  def init(opts), do: opts

  def call(conn, opts) do
    conn = fetch_current_user(conn)

    cond do
      opts == :require and is_nil(conn.assigns.current_user) ->
        conn
        |> put_flash(:error, "You must log in to access this page.")
        |> redirect(to: "/login")
        |> halt()

      opts == :redirect_if_authenticated and conn.assigns.current_user ->
        conn
        |> redirect(to: "/")
        |> halt()

      true ->
        conn
    end
  end

  def sign(%{id: id}), do: Phoenix.Token.sign(Endpoint, @salt, id)

  def verify(token) when is_binary(token) do
    with {:ok, user_id} <- Phoenix.Token.verify(Endpoint, @salt, token, max_age: @max_age),
         {:ok, user} <- Users.get(user_id) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  def verify(_token), do: :error

  def log_in(conn, user) do
    token = sign(user)

    conn
    |> put_session(@session_key, token)
    |> assign(:current_user, user)
    |> assign(:user_token, token)
  end

  def log_out(conn) do
    conn
    |> delete_session(@session_key)
    |> assign(:current_user, nil)
    |> assign(:user_token, nil)
  end

  defp fetch_current_user(conn) do
    case get_session(conn, @session_key) do
      nil ->
        conn
        |> assign(:current_user, nil)
        |> assign(:user_token, nil)

      token ->
        case verify(token) do
          {:ok, user} ->
            conn
            |> assign(:current_user, user)
            |> assign(:user_token, token)

          :error ->
            conn
            |> delete_session(@session_key)
            |> assign(:current_user, nil)
            |> assign(:user_token, nil)
        end
    end
  end
end
