defmodule PeekTest do
  use ExUnit.Case

  import Monad

  describe "peek/2" do
    test "returns data unchanged for {:ok, value}" do
      original = {:ok, "John"}
      result = peek(original, fn name -> "Hello, #{name}!" end)
      assert result == original
    end

    test "returns data unchanged for {:error, reason}" do
      original = {:error, :not_found}
      result = peek(original, fn reason -> "Error: #{reason}" end)
      assert result == original
    end

    test "returns data unchanged for :error atom" do
      original = :error
      result = peek(original, fn reason -> "Error: #{inspect(reason)}" end)
      assert result == original
    end

    test "returns data unchanged for :ok atom" do
      original = :ok
      result = peek(original, fn _ -> "processed" end)
      assert result == original
    end

    test "calls function with payload from {:ok, value}" do
      test_pid = self()

      peek({:ok, "John"}, fn name ->
        send(test_pid, {:called_with, name})
      end)

      assert_receive {:called_with, "John"}
    end

    test "calls function with payload from {:error, reason}" do
      test_pid = self()

      peek({:error, :not_found}, fn reason ->
        send(test_pid, {:called_with, reason})
      end)

      assert_receive {:called_with, :not_found}
    end

    test "calls function with tuple payload" do
      test_pid = self()

      peek({:ok, "John", 25}, fn {name, age} ->
        send(test_pid, {:called_with, name, age})
      end)

      assert_receive {:called_with, "John", 25}
    end

    test "calls function with empty payload from atoms" do
      test_pid = self()

      peek(:ok, fn payload ->
        send(test_pid, {:called_with, payload})
      end)

      assert_receive {:called_with, {}}

      peek(:error, fn payload ->
        send(test_pid, {:called_with, payload})
      end)

      assert_receive {:called_with, {}}
    end

    test "can be used for side effects like logging" do
      test_pid = self()

      log_fn = fn value ->
        send(test_pid, {:logged, "Processing: #{inspect(value)}"})
      end

      result =
        {:ok, "John"}
        |> peek(log_fn)
        |> map(fn name -> String.upcase(name) end)

      assert result == {:ok, "JOHN"}
      assert_receive {:logged, "Processing: \"John\""}
    end

    test "ignores return value of peekped function" do
      original = {:ok, "John"}

      result = peek(original, fn _ ->
        %{some: "complex", return: "value"}
      end)

      assert result == original
    end

    test "handles function that raises exception" do
      original = {:ok, "John"}

      assert_raise RuntimeError, "test error", fn ->
        peek(original, fn _ -> raise "test error" end)
      end
    end

    test "works in pipeline for debugging" do
      test_pid = self()

      result =
        {:ok, 5}
        |> peek(fn x -> send(test_pid, {:step1, x}) end)
        |> map(fn x -> x * 2 end)
        |> peek(fn x -> send(test_pid, {:step2, x}) end)
        |> map(fn x -> x + 1 end)

      assert result == {:ok, 11}
      assert_receive {:step1, 5}
      assert_receive {:step2, 10}
    end
  end
end
