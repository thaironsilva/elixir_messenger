defmodule ElixirMessenger.Users.Password do
  @moduledoc """
  Hashes and verifies user passwords using PBKDF2-HMAC-SHA256.

  Hashes are self-contained strings of the form
  `$pbkdf2-sha256$<iterations>$<salt>$<digest>`, where salt and digest are
  Base64 encoded.
  """

  @algorithm :sha256
  @iterations 100_000
  @salt_bytes 16
  @key_length 32

  @doc """
  Hashes a plaintext password.
  """
  def hash(password) when is_binary(password) do
    salt = :crypto.strong_rand_bytes(@salt_bytes)
    digest = :crypto.pbkdf2_hmac(@algorithm, password, salt, @iterations, @key_length)

    "$pbkdf2-sha256$#{@iterations}$#{Base.encode64(salt)}$#{Base.encode64(digest)}"
  end

  @doc """
  Checks a plaintext password against a stored hash.
  """
  def matches?(password, stored) when is_binary(password) and is_binary(stored) do
    with ["", "pbkdf2-sha256", iterations, salt, digest] <- String.split(stored, "$"),
         {iterations, ""} <- Integer.parse(iterations),
         {:ok, salt} <- Base.decode64(salt),
         {:ok, digest} <- Base.decode64(digest) do
      actual = :crypto.pbkdf2_hmac(@algorithm, password, salt, iterations, byte_size(digest))
      :crypto.hash_equals(actual, digest)
    else
      _ -> false
    end
  end

  def matches?(_password, _stored), do: false
end
