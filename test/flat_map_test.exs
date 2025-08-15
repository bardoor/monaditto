defmodule FlatMapTest do
  use ExUnit.Case

  import Monad

  describe "flat_map/2 with single values" do
    test "applies function to {:ok, value}" do
      greet = fn name -> {:ok, "Hello, #{name}!"} end
      assert flat_map({:ok, "John"}, greet) == {:ok, "Hello, John!"}
    end

    test "passes through {:error, reason}" do
      greet = fn name -> {:ok, "Hello, #{name}!"} end
      assert flat_map({:error, :not_found}, greet) == {:error, :not_found}
    end

    test "passes through :error atom" do
      greet = fn name -> {:ok, "Hello, #{name}!"} end
      assert flat_map(:error, greet) == :error
    end

    test "handles function returning error" do
      validate = fn name ->
        if String.length(name) > 0 do
          {:ok, "Valid: #{name}"}
        else
          {:error, :empty_name}
        end
      end

      assert flat_map({:ok, "John"}, validate) == {:ok, "Valid: John"}
      assert flat_map({:ok, ""}, validate) == {:error, :empty_name}
    end

    test "handles tuples with multiple values" do
      format_info = fn {name, age} -> {:ok, "#{name} is #{age} years old"} end
      result = flat_map({:ok, "John", 25}, format_info)
      assert result == {:ok, "John is 25 years old"}
    end
  end

  describe "flat_map/2 with lists" do
    test "processes list of successful values" do
      double = fn x -> {:ok, x * 2} end
      data = [{:ok, 1}, {:ok, 2}, {:ok, 3}]
      assert flat_map(data, double) == {:ok, [2, 4, 6]}
    end

    test "stops at first error" do
      double = fn x -> {:ok, x * 2} end
      data = [{:ok, 1}, {:error, :not_found}, {:ok, 3}]
      assert flat_map(data, double) == {:error, :not_found}
    end

    test "handles function returning errors" do
      validate_even = fn x ->
        if rem(x, 2) == 0 do
          {:ok, x * 2}
        else
          {:error, :odd_number}
        end
      end

      data = [{:ok, 2}, {:ok, 4}, {:ok, 6}]
      assert flat_map(data, validate_even) == {:ok, [4, 8, 12]}

      data = [{:ok, 1}, {:ok, 2}, {:ok, 3}]
      assert flat_map(data, validate_even) == {:error, :odd_number}
    end

    test "processes mixed tuple payloads" do
      format_name_age = fn {name, age} -> {:ok, "#{name} is #{age * 2} years old"} end
      data = [{:ok, "John", 25}, {:ok, "Jane", 30}]
      expected = {:ok, ["John is 50 years old", "Jane is 60 years old"]}
      assert flat_map(data, format_name_age) == expected
    end

    test "handles empty list" do
      double = fn x -> {:ok, x * 2} end
      assert flat_map([], double) == {:ok, []}
    end

    test "handles list with :ok atoms" do
      add_prefix = fn _ -> {:ok, "processed"} end
      data = [:ok, :ok, :ok]
      assert flat_map(data, add_prefix) == {:ok, ["processed", "processed", "processed"]}
    end

    test "chains multiple flat_map operations" do
      data = [{:ok, "John", 25}, {:ok, "Brother Tom", 30}]

      result1 = flat_map(data, fn {name, age} -> {:ok, {name, age * 2}} end)
      assert result1 == {:ok, [{"John", 50}, {"Brother Tom", 60}]}

      result2 = flat_map(result1, fn list ->
        mapped = Enum.map(list, fn {name, age} -> "#{name} is #{age} years old" end)
        {:ok, mapped}
      end)

      expected = {:ok, ["John is 50 years old", "Brother Tom is 60 years old"]}
      assert result2 == expected
    end

    test "chains with error interruption" do
      data = [{:ok, "John", 25}, {:error, :not_found}, {:ok, "Brother Tom", 30}]

      result =
        data
        |> flat_map(fn {name, age} -> {:ok, name, age * 2} end)
        |> flat_map(fn {name, age} -> {:ok, "#{name} is #{age} years old"} end)

      assert result == {:error, :not_found}
    end
  end
end
