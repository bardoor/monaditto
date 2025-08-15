defmodule ValidationTest do
  use ExUnit.Case

  import Monad

  describe "any_error?/1" do
    test "returns false for {:ok, value}" do
      assert any_error?({:ok, "John"}) == false
    end

    test "returns true for {:error, reason}" do
      assert any_error?({:error, :not_found}) == true
    end

    test "returns true for :error atom" do
      assert any_error?(:error) == true
    end

    test "returns false for :ok atom" do
      assert any_error?(:ok) == false
    end

    test "returns false for list with all ok values" do
      data = [{:ok, "John"}, {:ok, "Jane"}, {:ok, "Bob"}]
      assert any_error?(data) == false
    end

    test "returns true for list with any error value" do
      data = [{:ok, "John"}, {:error, :not_found}, {:ok, "Bob"}]
      assert any_error?(data) == true
    end

    test "returns true for list with only error values" do
      data = [{:error, :not_found}, {:error, :invalid}, {:error, :timeout}]
      assert any_error?(data) == true
    end

    test "returns false for empty list" do
      assert any_error?([]) == false
    end

    test "returns false for list with :ok atoms" do
      data = [:ok, :ok, :ok]
      assert any_error?(data) == false
    end

    test "returns true for list with :error atoms" do
      data = [:ok, :error, :ok]
      assert any_error?(data) == true
    end

    test "returns true for list with mixed error types" do
      data = [{:ok, "John"}, :error, {:error, :not_found}]
      assert any_error?(data) == true
    end

    test "handles list with complex payloads" do
      data = [
        {:ok, %{name: "John", age: 25}},
        {:ok, %{name: "Jane", age: 30}},
        {:error, %{code: 404, message: "Not found"}}
      ]

      assert any_error?(data) == true
    end

    test "returns false for list with only successful complex payloads" do
      data = [
        {:ok, %{name: "John", age: 25}},
        {:ok, %{name: "Jane", age: 30}},
        {:ok, %{name: "Bob", age: 35}}
      ]

      assert any_error?(data) == false
    end
  end

  describe "all_ok?/1" do
    test "returns true for {:ok, value}" do
      assert all_ok?({:ok, "John"}) == true
    end

    test "returns false for {:error, reason}" do
      assert all_ok?({:error, :not_found}) == false
    end

    test "returns false for :error atom" do
      assert all_ok?(:error) == false
    end

    test "returns true for :ok atom" do
      assert all_ok?(:ok) == true
    end

    test "returns true for list with all ok values" do
      data = [{:ok, "John"}, {:ok, "Jane"}, {:ok, "Bob"}]
      assert all_ok?(data) == true
    end

    test "returns false for list with any error value" do
      data = [{:ok, "John"}, {:error, :not_found}, {:ok, "Bob"}]
      assert all_ok?(data) == false
    end

    test "returns false for list with only error values" do
      data = [{:error, :not_found}, {:error, :invalid}, {:error, :timeout}]
      assert all_ok?(data) == false
    end

    test "returns true for empty list" do
      assert all_ok?([]) == true
    end

    test "returns true for list with :ok atoms" do
      data = [:ok, :ok, :ok]
      assert all_ok?(data) == true
    end

    test "returns false for list with :error atoms" do
      data = [:ok, :error, :ok]
      assert all_ok?(data) == false
    end

    test "returns false for list with mixed error types" do
      data = [{:ok, "John"}, :error, {:error, :not_found}]
      assert all_ok?(data) == false
    end

    test "handles list with complex payloads" do
      data = [
        {:ok, %{name: "John", age: 25}},
        {:ok, %{name: "Jane", age: 30}},
        {:ok, %{name: "Bob", age: 35}}
      ]

      assert all_ok?(data) == true
    end

    test "returns false for list with any error in complex payloads" do
      data = [
        {:ok, %{name: "John", age: 25}},
        {:error, %{code: 404, message: "Not found"}},
        {:ok, %{name: "Bob", age: 35}}
      ]

      assert all_ok?(data) == false
    end

    test "handles mixed tuple sizes" do
      data = [
        {:ok, "John"},
        {:ok, "Jane", 30},
        {:ok, "Bob", 35, "Engineer"}
      ]

      assert all_ok?(data) == true
    end

    test "returns false for mixed success and error with different tuple sizes" do
      data = [
        {:ok, "John"},
        {:error, "Not found", 404},
        {:ok, "Bob", 35, "Engineer"}
      ]

      assert all_ok?(data) == false
    end
  end

  describe "validation function combinations" do
    test "any_error? and all_ok? are complementary for lists" do
      test_cases = [
        [{:ok, 1}, {:ok, 2}, {:ok, 3}],
        [{:error, :a}, {:error, :b}],
        [{:ok, 1}, {:error, :a}, {:ok, 3}],
        [],
        [:ok, :ok],
        [:error, :error],
        [:ok, :error]
      ]

      Enum.each(test_cases, fn data ->
        # For lists: any_error? and all_ok? should be opposite
        # Exception: empty list returns false for any_error? and true for all_ok?
        if data == [] do
          assert any_error?(data) == false
          assert all_ok?(data) == true
        else
          assert any_error?(data) != all_ok?(data)
        end
      end)
    end

    test "any_error? and all_ok? are complementary for single values" do
      test_cases = [
        {:ok, "value"},
        {:error, :reason},
        :ok,
        :error
      ]

      Enum.each(test_cases, fn data ->
        assert any_error?(data) != all_ok?(data)
      end)
    end
  end
end
