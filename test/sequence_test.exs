defmodule SequenceTest do
  use ExUnit.Case

  import Monad

  describe "sequence until error" do
    test "all ok without payload" do
      assert sequence([:ok, :ok, :ok]) == :ok
    end

    test "all ok with payload" do
      assert sequence([{:ok, 1}, {:ok, 2}, {:ok, 3}]) == {:ok, [1, 2, 3]}
    end

    test "all ok with payload and error" do
      assert sequence([{:ok, 1}, {:error, 2}, {:ok, 3}]) == {:error, 2}
    end

    test "mixed ok types" do
      assert sequence([{:ok, 1}, :ok, {:ok, 3}]) == {:ok, [1, 3]}
    end

    test "tuple payload" do
      assert sequence([{:ok, {1, 2}}, {:ok, {3, 4}}]) == {:ok, [{1, 2}, {3, 4}]}
    end
  end
end
