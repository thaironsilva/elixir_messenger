defmodule ElixirMessenger.UsersTest do
  use ExUnit.Case, async: false

  alias ElixirMessenger.Users
  alias ElixirMessenger.Users.Password
  alias ElixirMessenger.Users.User

  setup do
    :ets.delete_all_objects(:users)
    :ets.delete_all_objects(:users_by_name)
    :ok
  end

  describe "insert/1" do
    test "inserts a user with a hashed password" do
      user = %User{
        name: "user",
        password: "123pass"
      }

      assert {:ok, %User{id: id, name: "user", password: stored_password}} = Users.insert(user)
      assert not is_nil(id)
      refute stored_password == "123pass"
      assert Password.verify("123pass", stored_password)
    end

    test "does not insert a user with a duplicated name" do
      user1 = %User{
        name: "user",
        password: "123pass"
      }

      user2 = %User{
        name: "user",
        password: "456pass"
      }

      assert {:ok, %User{name: "user"}} = Users.insert(user1)
      assert {:error, :already_exists} = Users.insert(user2)
    end
  end

  describe "get_by_name/1" do
    test "returns the user with the given name" do
      user = %User{
        name: "user",
        password: "123pass"
      }

      assert {:ok, inserted} = Users.insert(user)
      assert {:ok, ^inserted} = Users.get_by_name("user")
    end

    test "returns not_found when no user has the given name" do
      assert {:error, :not_found} = Users.get_by_name("missing")
    end
  end

  describe "update/1" do
    test "updates a user" do
      assert {:ok, user} = Users.insert(%User{name: "user", password: "123pass"})

      assert {:ok, %User{name: "renamed", password: stored_password}} =
               Users.update(%{user | name: "renamed"})

      assert stored_password == user.password
      assert {:ok, %User{name: "renamed"}} = Users.get_by_name("renamed")
      assert {:error, :not_found} = Users.get_by_name("user")
    end

    test "does not change the password" do
      assert {:ok, user} = Users.insert(%User{name: "user", password: "123pass"})

      assert {:ok, %User{password: stored_password}} =
               Users.update(%{user | password: "newpass"})

      assert stored_password == user.password
      assert Password.verify("123pass", stored_password)
      refute Password.verify("newpass", stored_password)
    end

    test "does not rename to an existing name" do
      assert {:ok, _user1} = Users.insert(%User{name: "user1", password: "123pass"})
      assert {:ok, user2} = Users.insert(%User{name: "user2", password: "123pass"})

      assert {:error, :already_exists} = Users.update(%{user2 | name: "user1"})
      assert {:ok, %User{name: "user2"}} = Users.get_by_name("user2")
    end

    test "returns not_found for an unknown id" do
      user = %User{id: Ecto.UUID.generate(), name: "user", password: "123pass"}

      assert {:error, :not_found} = Users.update(user)
    end
  end

  describe "update_password/2" do
    test "hashes and stores the new password" do
      assert {:ok, user} = Users.insert(%User{name: "user", password: "123pass"})

      assert {:ok, %User{name: "user", password: stored_password}} =
               Users.update_password(user, "newpass")

      refute stored_password == user.password
      assert Password.verify("newpass", stored_password)
      refute Password.verify("123pass", stored_password)
    end

    test "returns not_found for an unknown id" do
      user = %User{id: Ecto.UUID.generate(), name: "user", password: "123pass"}

      assert {:error, :not_found} = Users.update_password(user, "newpass")
    end
  end

  describe "delete/1" do
    test "deletes a user and its name index" do
      assert {:ok, user} = Users.insert(%User{name: "user", password: "123pass"})

      assert :ok = Users.delete(user.id)
      assert {:error, :not_found} = Users.get(user.id)
      assert {:error, :not_found} = Users.get_by_name("user")
    end

    test "returns not_found for an unknown id" do
      assert {:error, :not_found} = Users.delete(Ecto.UUID.generate())
    end
  end
end
