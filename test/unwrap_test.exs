defmodule UnwrapTest do
  use ExUnit.Case

  import Monad

  describe "unwrap/2" do
    test "returns value from {:ok, value}" do
      assert unwrap({:ok, "John"}) == "John"
    end

    test "returns default for {:error, reason}" do
      assert unwrap({:error, :not_found}, "Default") == "Default"
    end

    test "returns nil as default when not provided for error" do
      assert unwrap({:error, :not_found}) == nil
    end

    test "returns default for :error atom" do
      assert unwrap(:error, "Default") == "Default"
    end

    test "returns nil for :error atom when no default" do
      assert unwrap(:error) == nil
    end

    test "returns payload from :ok atom" do
      assert unwrap(:ok) == {}
    end

    test "returns payload from :ok atom with default" do
      assert unwrap(:ok, "Default") == {}
    end

    test "handles tuple payloads" do
      assert unwrap({:ok, "John", 25}) == {"John", 25}
    end

    test "handles single tuple payload" do
      assert unwrap({:ok, "John"}) == "John"
    end

    test "handles complex data structures" do
      data = %{name: "John", age: 25}
      assert unwrap({:ok, data}) == data
    end

    test "returns provided default for any error" do
      assert unwrap({:error, %{code: 404}}, []) == []
      assert unwrap({:error, "custom error"}, 0) == 0
      assert unwrap({:error, {:nested, :error}}, :fallback) == :fallback
    end

    test "works with different default types" do
      assert unwrap({:error, :not_found}, "string default") == "string default"
      assert unwrap({:error, :not_found}, 42) == 42
      assert unwrap({:error, :not_found}, [1, 2, 3]) == [1, 2, 3]
      assert unwrap({:error, :not_found}, %{key: "value"}) == %{key: "value"}
    end
  end

  describe "unwrap!/1" do
    test "returns value from {:ok, value}" do
      assert unwrap!({:ok, "John"}) == "John"
    end

    test "raises error for {:error, reason}" do
      assert_raise RuntimeError, "Error: :not_found", fn ->
        unwrap!({:error, :not_found})
      end
    end

    test "raises error for :error atom" do
      assert_raise RuntimeError, "Error: {}", fn ->
        unwrap!(:error)
      end
    end

    test "returns payload from :ok atom" do
      assert unwrap!(:ok) == {}
    end

    test "handles tuple payloads" do
      assert unwrap!({:ok, "John", 25}) == {"John", 25}
    end

    test "handles single tuple payload" do
      assert unwrap!({:ok, "John"}) == "John"
    end

    test "raises with complex error payloads" do
      error_data = %{code: 404, message: "Not found"}

      assert_raise RuntimeError, "Error: %{code: 404, message: \"Not found\"}", fn ->
        unwrap!({:error, error_data})
      end
    end

    test "raises with tuple error payloads" do
      assert_raise RuntimeError, "Error: {\"not_found\", \"resource missing\"}", fn ->
        unwrap!({:error, "not_found", "resource missing"})
      end
    end

    test "raises with nested error structures" do
      nested_error = {:validation, %{field: "email", reason: "invalid"}}

      assert_raise RuntimeError, fn ->
        unwrap!({:error, nested_error})
      end
    end

    test "handles complex successful data structures" do
      data = %{users: [%{name: "John"}, %{name: "Jane"}]}
      assert unwrap!({:ok, data}) == data
    end

    test "works in pipeline until error" do
      result =
        {:ok, 5}
        |> map(fn x -> x * 2 end)
        |> unwrap!()

      assert result == 10
    end

    test "interrupts pipeline on error" do
      assert_raise RuntimeError, "Error: :invalid_input", fn ->
        {:error, :invalid_input}
        |> map(fn x -> x * 2 end)
        |> unwrap!()
      end
    end
  end
end
