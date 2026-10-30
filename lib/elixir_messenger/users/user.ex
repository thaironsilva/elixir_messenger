defmodule ElixirMessenger.Users.User do
  @doc """
  Chat user
  """

  @enforce_keys [:name, :password]
  defstruct [
    :id,
    :name,
    :password
  ]
end
