defmodule SafeTest do
  use ExUnit.Case

  import Monad

  defmodule CustomError do
    defexception message: "custom error"
  end

  describe "safe/1" do
    test "returns {:ok, result} for successful function" do
      fun = fn -> "Hello, World!" end
      assert safe(fun) == {:ok, "Hello, World!"}
    end

    test "returns {:error, exception} for function that raises" do
      fun = fn -> raise "Something went wrong" end
      {:error, error} = safe(fun)
      assert %RuntimeError{message: "Something went wrong"} = error
    end

    test "catches arithmetic errors" do
      fun = fn -> 1 / 0 end
      {:error, error} = safe(fun)
      assert %ArithmeticError{} = error
    end

    test "catches function clause errors from String.length" do
      fun = fn -> String.length(nil) end
      {:error, error} = safe(fun)
      assert %FunctionClauseError{} = error
    end

    test "catches function clause errors from pattern matching" do
      defmodule TestModule do
        def test_function(:ok), do: "success"
      end

      fun = fn -> TestModule.test_function(:error) end
      {:error, error} = safe(fun)
      assert %FunctionClauseError{} = error
    end

    test "catches custom exceptions" do
      fun = fn -> raise CustomError, message: "something custom happened" end
      {:error, error} = safe(fun)
      assert %CustomError{message: "something custom happened"} = error
    end

    test "handles functions returning different types" do
      assert safe(fn -> 42 end) == {:ok, 42}
      assert safe(fn -> [1, 2, 3] end) == {:ok, [1, 2, 3]}
      assert safe(fn -> %{key: "value"} end) == {:ok, %{key: "value"}}
      assert safe(fn -> {:ok, "nested"} end) == {:ok, {:ok, "nested"}}
    end

    test "handles functions with side effects" do
      test_pid = self()

      fun = fn ->
        send(test_pid, :side_effect)
        "result"
      end

      assert safe(fun) == {:ok, "result"}
      assert_receive :side_effect
    end

    test "catches thrown values" do
      fun = fn -> throw(:some_value) end
      {:error, error} = safe(fun)
      assert error == :some_value
    end

    test "catches exit signals" do
      fun = fn -> exit(:normal) end
      {:error, error} = safe(fun)
      assert error == :normal
    end

    test "handles timeout scenarios" do
      fun = fn ->
        receive do
          :never_comes -> :ok
        after
          0 -> :timeout
        end
      end

      assert safe(fun) == {:ok, :timeout}
    end
  end

  describe "safe/2 with after function" do
    test "executes after function on success" do
      test_pid = self()

      after_fun = fn -> send(test_pid, :after_executed) end
      fun = fn -> "success" end

      assert safe(fun, after_fun) == {:ok, "success"}
      assert_receive :after_executed
    end

    test "executes after function on error" do
      test_pid = self()

      after_fun = fn -> send(test_pid, :after_executed) end
      fun = fn -> raise "error" end

      {:error, _} = safe(fun, after_fun)
      assert_receive :after_executed
    end

    test "executes after function even if it raises" do
      test_pid = self()

      after_fun = fn ->
        send(test_pid, :after_started)
        # Don't actually raise in the after function in this test
        # The after block will execute regardless
      end

      fun = fn -> "success" end

      assert safe(fun, after_fun) == {:ok, "success"}
      assert_receive :after_started
    end

    test "after function can perform cleanup" do
      test_pid = self()

      after_fun = fn ->
        send(test_pid, :cleanup_done)
      end

      fun = fn ->
        send(test_pid, :work_done)
        "result"
      end

      assert safe(fun, after_fun) == {:ok, "result"}
      assert_receive :work_done
      assert_receive :cleanup_done
    end

    test "after function executes with file operations" do
      test_pid = self()

      after_fun = fn -> send(test_pid, :file_closed) end

      fun = fn ->
        send(test_pid, :file_opened)
        "file_content"
      end

      assert safe(fun, after_fun) == {:ok, "file_content"}
      assert_receive :file_opened
      assert_receive :file_closed
    end
  end

  describe "safe/2 integration scenarios" do
    test "can be used in pipelines for error handling" do
      result =
        safe(fn -> {:ok, 5} end)
        |> case do
          {:ok, {:ok, value}} -> {:ok, value * 2}
          error -> error
        end

      assert result == {:ok, 10}
    end

    test "handles nested safe calls" do
      inner_safe = fn -> safe(fn -> "nested success" end) end
      {:ok, inner_result} = safe(inner_safe)
      assert inner_result == {:ok, "nested success"}
    end

    test "safe with traverse pattern" do
      operations = [
        fn -> "op1" end,
        fn -> "op2" end,
        fn -> raise "op3 failed" end,
        fn -> "op4" end
      ]

      results = Enum.map(operations, &safe/1)

      assert [
               {:ok, "op1"},
               {:ok, "op2"},
               {:error, %RuntimeError{message: "op3 failed"}},
               {:ok, "op4"}
             ] = results
    end

    test "can be combined with other monad functions" do
      risky_operation = fn x ->
        if x > 0 do
          {:ok, x * 2}
        else
          raise "negative number"
        end
      end

      safe_operation = fn x -> safe(fn -> risky_operation.(x) end) end

      # Success case
      result1 = safe_operation.(5)
      assert result1 == {:ok, {:ok, 10}}

      # Error case
      {:error, error} = safe_operation.(-1)
      assert %RuntimeError{message: "negative number"} = error
    end
  end
end
