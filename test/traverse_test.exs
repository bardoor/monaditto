defmodule TraverseTest do
  use ExUnit.Case

  import Monad

  describe "traverse/2 with lists" do
    test "applies function to each element and collects results" do
      double = fn x -> {:ok, x * 2} end
      assert traverse([1, 2, 3], double) == {:ok, [2, 4, 6]}
    end

    test "stops at first error" do
      map_even = fn x ->
        if rem(x, 2) == 0 do
          {:ok, x * 2}
        else
          {:error, :odd}
        end
      end

      assert traverse([1, 2, 3], map_even) == {:error, :odd}
      assert traverse([2, 4, 6], map_even) == {:ok, [4, 8, 12]}
    end

    test "handles empty list" do
      double = fn x -> {:ok, x * 2} end
      assert traverse([], double) == {:ok, []}
    end

    test "handles functions returning complex data" do
      format_user = fn id ->
        {:ok, %{id: id, name: "User #{id}", active: true}}
      end

      result = traverse([1, 2, 3], format_user)

      expected = {
        :ok,
        [
          %{id: 1, name: "User 1", active: true},
          %{id: 2, name: "User 2", active: true},
          %{id: 3, name: "User 3", active: true}
        ]
      }

      assert result == expected
    end

    test "handles validation functions" do
      validate_positive = fn x ->
        if x > 0 do
          {:ok, x}
        else
          {:error, :not_positive}
        end
      end

      assert traverse([1, 2, 3], validate_positive) == {:ok, [1, 2, 3]}
      assert traverse([1, -1, 3], validate_positive) == {:error, :not_positive}
      assert traverse([-1, 2, 3], validate_positive) == {:error, :not_positive}
    end

    test "handles range inputs" do
      square = fn x -> {:ok, x * x} end
      assert traverse(1..3, square) == {:ok, [1, 4, 9]}
    end

    test "handles functions with complex error reasons" do
      divide_by_two = fn x ->
        if rem(x, 2) == 0 do
          {:ok, div(x, 2)}
        else
          {:error, {:not_divisible, x}}
        end
      end

      assert traverse([2, 4, 6], divide_by_two) == {:ok, [1, 2, 3]}
      assert traverse([2, 3, 6], divide_by_two) == {:error, {:not_divisible, 3}}
    end

    test "preserves order of results" do
      add_index = fn {item, index} -> {:ok, "#{index}: #{item}"} end
      items = ["a", "b", "c"]
      indexed_items = Enum.with_index(items)

      result = traverse(indexed_items, add_index)
      assert result == {:ok, ["0: a", "1: b", "2: c"]}
    end

    test "handles large lists efficiently" do
      large_list = 1..1000
      identity = fn x -> {:ok, x} end

      result = traverse(large_list, identity)
      expected_list = Enum.to_list(large_list)

      assert result == {:ok, expected_list}
    end

    test "stops early on error in large list" do
      large_list = 1..1000

      fail_at_500 = fn x ->
        if x == 500 do
          {:error, :failed_at_500}
        else
          {:ok, x}
        end
      end

      assert traverse(large_list, fail_at_500) == {:error, :failed_at_500}
    end
  end

  describe "traverse/2 with single values" do
    test "applies function to {:ok, value}" do
      double = fn x -> {:ok, x * 2} end
      assert traverse({:ok, 5}, double) == {:ok, 10}
    end

    test "passes through {:error, reason}" do
      double = fn x -> {:ok, x * 2} end
      assert traverse({:error, :not_found}, double) == {:error, :not_found}
    end

    test "passes through :error atom" do
      double = fn x -> {:ok, x * 2} end
      assert traverse(:error, double) == :error
    end

    test "applies function to :ok atom" do
      get_default = fn _ -> {:ok, "default"} end
      assert traverse(:ok, get_default) == {:ok, "default"}
    end

    test "handles function returning error for single value" do
      validate_even = fn x ->
        if rem(x, 2) == 0 do
          {:ok, x}
        else
          {:error, :odd}
        end
      end

      assert traverse({:ok, 4}, validate_even) == {:ok, 4}
      assert traverse({:ok, 3}, validate_even) == {:error, :odd}
    end

    test "handles tuple payloads" do
      format_name = fn {first, last} -> {:ok, "#{first} #{last}"} end
      result = traverse({:ok, "John", "Doe"}, format_name)
      assert result == {:ok, "John Doe"}
    end
  end
end
