defmodule ElixirMessenger.Users do
  @doc """
  API for users
  """

  @users_table :users

  alias ElixirMessenger.Repo
  alias ElixirMessenger.Users.Password
  alias ElixirMessenger.Users.User

  @spec get(Ecto.UUID.t()) :: {:ok, %User{}} | {:error, :not_found}
  def get(id) do
    Repo.get(@users_table, id)
  end

  @spec get_by_name(String.t()) :: {:ok, %User{}} | {:error, :not_found}
  def get_by_name(name) do
    Repo.get_by(@users_table, :name, name)
  end

  @spec all() :: list()
  def all() do
    Repo.all(@users_table)
  end

  @spec insert(%User{}) :: {:ok, %User{}} | {:error, :already_exists}
  def insert(%User{password: password} = user) do
    Repo.insert(@users_table, %{user | password: Password.hash(password)})
  end

  @spec update(%User{}) ::
          {:ok, %User{}} | {:error, :not_found} | {:error, :already_exists}
  def update(%User{id: id} = user) do
    with {:ok, current} <- get(id) do
      Repo.update(@users_table, id, %{user | password: current.password})
    end
  end

  @spec update_password(%User{}, String.t()) ::
          {:ok, %User{}} | {:error, :not_found}
  def update_password(%User{id: id}, new_password) when is_binary(new_password) do
    with {:ok, current} <- get(id) do
      Repo.update(@users_table, id, %{current | password: Password.hash(new_password)})
    end
  end

  @spec delete(Ecto.UUID.t()) :: :ok | {:error, :not_found}
  def delete(id) do
    Repo.delete(@users_table, id)
  end
end
