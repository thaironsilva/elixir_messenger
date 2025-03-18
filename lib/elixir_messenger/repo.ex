defmodule ElixirMessenger.Repo do
  use Ecto.Repo,
    otp_app: :elixir_messenger,
    adapter: Ecto.Adapters.Postgres
end
