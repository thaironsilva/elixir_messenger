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

  @doc """
  Validates the fields required to register a user.
  """
  def validate_registration(name, password, password_confirmation) do
    cond do
      blank?(name) -> {:error, :name_required}
      blank?(password) -> {:error, :password_required}
      password != password_confirmation -> {:error, :password_mismatch}
      true -> :ok
    end
  end

  defp blank?(value), do: not is_binary(value) or String.trim(value) == ""
end
