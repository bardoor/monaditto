defmodule BimapTest do
  use ExUnit.Case

  import Monad

  describe "bimap/3" do
    test "applies success function to {:ok, value}" do
      greet = fn name -> "Hello, #{name}!" end
      error_handler = fn reason -> "Error: #{reason}" end

      assert bimap({:ok, "John"}, greet, error_handler) == {:ok, "Hello, John!"}
    end

    test "applies error function to {:error, reason}" do
      greet = fn name -> "Hello, #{name}!" end
      error_handler = fn reason -> "Error: #{reason}" end

      assert bimap({:error, :not_found}, greet, error_handler) == {:error, "Error: not_found"}
    end

    test "applies error function to :error atom" do
      greet = fn name -> "Hello, #{name}!" end
      error_handler = fn reason -> "Error: #{inspect(reason)}" end

      assert bimap(:error, greet, error_handler) == {:error, "Error: {}"}
    end

    test "handles success tuples with multiple values" do
      format_info = fn {name, age} -> "#{name} is #{age} years old" end
      error_handler = fn reason -> "Error: #{reason}" end

      result = bimap({:ok, "John", 25}, format_info, error_handler)
      assert result == {:ok, "John is 25 years old"}
    end

    test "handles error tuples with multiple values" do
      greet = fn name -> "Hello, #{name}!" end
      format_error = fn {code, message} -> "#{code}: #{message}" end

      result = bimap({:error, 404, "Not found"}, greet, format_error)
      assert result == {:error, "404: Not found"}
    end

    test "handles complex success transformations" do
      capitalize_name = fn %{first: first, last: last} -> "#{String.upcase(first)} #{String.upcase(last)}" end
      error_handler = fn _ -> "Failed" end

      data = %{first: "john", last: "doe"}
      result = bimap({:ok, data}, capitalize_name, error_handler)
      assert result == {:ok, "JOHN DOE"}
    end

    test "handles complex error transformations" do
      success_handler = fn x -> x * 2 end
      format_error = fn %{type: type, details: details} -> "#{type} error: #{details}" end

      error_data = %{type: "validation", details: "invalid input"}
      result = bimap({:error, error_data}, success_handler, format_error)
      assert result == {:error, "validation error: invalid input"}
    end

    test "functions can return same types" do
      to_string_fn = fn x -> "#{x}" end
      to_string_error = fn x -> "#{x}" end

      assert bimap({:ok, 42}, to_string_fn, to_string_error) == {:ok, "42"}
      assert bimap({:error, 404}, to_string_fn, to_string_error) == {:error, "404"}
    end

    test "works with :ok atom" do
      success_handler = fn _ -> "success" end
      error_handler = fn _ -> "error" end

      assert bimap(:ok, success_handler, error_handler) == {:ok, "success"}
    end
  end
end
