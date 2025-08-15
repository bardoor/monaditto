defmodule MapTest do
  use ExUnit.Case

  import Monad

  describe "map/2" do
    test "applies function to {:ok, value}" do
      greet = fn name -> "Hello, #{name}!" end
      assert map({:ok, "John"}, greet) == {:ok, "Hello, John!"}
    end

    test "passes through {:error, reason}" do
      greet = fn name -> "Hello, #{name}!" end
      assert map({:error, :not_found}, greet) == {:error, :not_found}
    end

    test "passes through :error atom" do
      greet = fn name -> "Hello, #{name}!" end
      assert map(:error, greet) == :error
    end

    test "handles tuples with multiple values" do
      format_info = fn {name, info} -> "Hello, #{name}! #{info}" end
      result = map({:ok, "John", "John's info"}, format_info)
      assert result == {:ok, "Hello, John! John's info"}
    end

    test "handles tuples with more than two values" do
      format_info = fn {name, age, city} -> "#{name}, #{age}, from #{city}" end
      result = map({:ok, "John", 25, "NYC"}, format_info)
      assert result == {:ok, "John, 25, from NYC"}
    end

    test "applies function to :ok atom" do
      assert map(:ok, fn _ -> "success" end) == {:ok, "success"}
    end
  end

  describe "map_error/2" do
    test "applies function to {:error, reason}" do
      format_error = fn reason -> "Error: #{reason}" end
      assert map_error({:error, :not_found}, format_error) == {:error, "Error: not_found"}
    end

    test "passes through {:ok, value}" do
      format_error = fn reason -> "Error: #{reason}" end
      assert map_error({:ok, "John"}, format_error) == {:ok, "John"}
    end

    test "applies function to :error atom with empty payload" do
      format_error = fn reason -> "Error: #{inspect(reason)}" end
      assert map_error(:error, format_error) == {:error, "Error: {}"}
    end

    test "handles error tuples with multiple values" do
      format_error = fn {reason, meta} -> "Error: #{reason} - #{meta}" end
      result = map_error({:error, :not_found, "meta info"}, format_error)
      assert result == {:error, "Error: not_found - meta info"}
    end

    test "handles complex error payload" do
      format_error = fn %{code: code, message: msg} -> "#{code}: #{msg}" end
      error_data = %{code: 404, message: "Not found"}
      result = map_error({:error, error_data}, format_error)
      assert result == {:error, "404: Not found"}
    end
  end
end
