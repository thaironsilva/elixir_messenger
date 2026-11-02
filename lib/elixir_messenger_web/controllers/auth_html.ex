defmodule ElixirMessengerWeb.AuthHTML do
  @moduledoc """
  Templates for the login and signup card.
  """

  use ElixirMessengerWeb, :html

  embed_templates "auth_html/*"
end
