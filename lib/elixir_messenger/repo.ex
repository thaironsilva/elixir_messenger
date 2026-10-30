defmodule ElixirMessenger.Repo do
  use GenServer

  @table_names [:users, :users_by_name]

  @unique_indexes %{
    users: {:users_by_name, :name}
  }

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Retrieves a record by id. Returns {:ok, data} or {:error, :not_found}.
  """
  def get(table_name, id) do
    case :ets.lookup(table_name, id) do
      [{^id, data}] -> {:ok, data}
      [] -> {:error, :not_found}
    end
  end

  @doc """
  Retrieves the first record matching the given unique index.

  Returns {:ok, data} or {:error, :not_found}.
  """
  def get_by(table_name, field, value) do
    {index_table, _field} = unique_index!(table_name, field)

    case :ets.lookup(index_table, value) do
      [{^value, id}] -> get(table_name, id)
      [] -> {:error, :not_found}
    end
  end

  @doc """
  Returns all records in a table as a list of data.
  """
  def all(table_name) do
    :ets.tab2list(table_name)
    |> Enum.map(fn {_id, data} -> data end)
  end

  @doc """
  Inserts a new record, enforcing the table's unique index.

  Returns {:ok, data} or {:error, :already_exists}.
  """
  def insert(table_name, data) do
    {index_table, index_field} = unique_index!(table_name)
    id = Ecto.UUID.generate()
    data = %{data | id: id}

    case :ets.insert_new(index_table, {Map.fetch!(data, index_field), id}) do
      true ->
        :ets.insert(table_name, {id, data})
        {:ok, data}

      false ->
        {:error, :already_exists}
    end
  end

  @doc """
  Updates a record by id, keeping the table's unique index in sync.

  Returns {:ok, data}, {:error, :not_found} or {:error, :already_exists}.
  """
  def update(table_name, id, data) do
    {index_table, index_field} = unique_index!(table_name)

    case :ets.lookup(table_name, id) do
      [{^id, current}] ->
        current_key = Map.fetch!(current, index_field)
        new_key = Map.fetch!(data, index_field)

        cond do
          current_key == new_key ->
            :ets.insert(table_name, {id, data})
            {:ok, data}

          :ets.insert_new(index_table, {new_key, id}) ->
            :ets.delete(index_table, current_key)
            :ets.insert(table_name, {id, data})
            {:ok, data}

          true ->
            {:error, :already_exists}
        end

      [] ->
        {:error, :not_found}
    end
  end

  @doc """
  Deletes a record by id, keeping the table's unique index in sync.

  Returns :ok or {:error, :not_found}.
  """
  def delete(table_name, id) do
    {index_table, index_field} = unique_index!(table_name)

    case :ets.lookup(table_name, id) do
      [{^id, data}] ->
        :ets.delete(index_table, Map.fetch!(data, index_field))
        :ets.delete(table_name, id)
        :ok

      [] ->
        {:error, :not_found}
    end
  end

  # =========================================================================
  # GenServer Callbacks
  # =========================================================================

  @impl true
  def init(_opts) do
    for t <- @table_names do
      :ets.new(t, [:named_table, :public, :set, read_concurrency: true])
    end

    {:ok, %{}}
  end

  defp unique_index!(table_name) do
    case Map.get(@unique_indexes, table_name) do
      nil -> raise ArgumentError, "#{inspect(table_name)} has no unique index"
      index -> index
    end
  end

  defp unique_index!(table_name, field) do
    case Map.get(@unique_indexes, table_name) do
      {index_table, ^field} ->
        {index_table, field}

      {_index_table, indexed_field} ->
        raise ArgumentError,
              "#{inspect(field)} is not indexed for #{inspect(table_name)} " <>
                "(indexed field: #{inspect(indexed_field)})"

      nil ->
        raise ArgumentError, "#{inspect(table_name)} has no unique index"
    end
  end
end
