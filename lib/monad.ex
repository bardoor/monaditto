defmodule Monad do
  @moduledoc """
  ## Introduction
  Hi there!
  This is a library for monads in Elixir - not with new structures, but with idiomatic Elixir tuples

  You have already seen monads in Elixir:

  ```elixir
  jose = %{first_name: "Jose", last_name: "Valim"}
  {:ok, "Jose"} = Map.fetch(jose, :first_name)    # Oh gosh! Monad `Maybe` - `Just "Jose"`
  :error = Map.fetch(jose, :age)                  # Holly moly! Monad `Maybe` - `Nothing`
  ```

  So, don't be afraid of monads, you use it every day
  I don't want you to change your entire codebase and break simplicity of elixir,
  so you could use any function from this library without wrapping it in a new structure like `%Just{}`, `%Nothing{}` etc

  ## Example
  You can chain operations naturally using pipelines, just like you do with regular Elixir code:

  ```elixir
  # Success path
  {:ok, "john"}
  |> Monad.map(&String.upcase/1)
  |> Monad.map(&String.reverse/1)
  # => {:ok, "NHOJ"}

  # Error path - stops at first error
  {:error, :not_found}
  |> Monad.map(&String.upcase/1)
  |> Monad.map(&String.reverse/1)
  # => {:error, :not_found}

  # Real-world example
  user_id
  |> fetch_user()           # {:ok, %User{}} | {:error, :not_found}
  |> Monad.map(&User.email/1)
  |> Monad.map(&send_email/1)
  # => {:ok, :email_sent} | {:error, :not_found}
  ```

  Other examples you could find in the documentation for dedicated functions
  """

  @type ok() :: {:ok, any()} | :ok
  @type error() :: {:error, any()} | :error
  @type result() :: ok() | error()

  defguardp is_ok(value) when is_tuple(value) and elem(value, 0) == :ok or value == :ok
  defguardp is_error(value) when is_tuple(value) and elem(value, 0) == :error or value == :error

  @doc """
  Unwraps a list of results

  During unwrapping, any values after `:ok` or `:error` will be grouped into a tuple if there are more than one,
  but if there is only `:error` atom instead of tuple, it will be treated as `{:error, :error}`:
    - `{:ok, :here, :there}` -> `{:here, :there}`
    - `{:error, :here, :there}` -> `{:here, :there}`
    - `{:ok, :here}` -> `:here`
    - `{:error, :here}` -> `:here`
    - `:error` -> `{:error, :error}`

  Strategies:
    - `:until_error` - stops at the first error (default)

  ## Examples
  Common `{:ok, value} | {:error, reason}` list:
  ```elixir
    data = [
      {:ok, "John"},
      {:ok, "Brother Tom"},
      {:error, :not_found},
      {:ok, "Jane"},
      {:error, :bad_query}
    ]

    iex> Monad.sequence(data)
    ...> {:error, :not_found}
  ```

  Mixed values (yes, it's possible, but remember that God watches you):
  ```elixir
    data = [
      {:ok, "John", "John's info"},
      :error,
      {:error, :not_found, "meta info"},
      {:ok, "Brother Tom"},
      {:error, :not_found}
    ]

    iex> Monad.sequence(data)
    ...> :error

    iex> Monad.sequence([{:ok, "John"}, {:ok, "Brother Tom"}])
    ...> {:ok, ["John", "Brother Tom"]}
  ```
  """
  @spec sequence([result()], :until_error) :: result()
  def sequence(data, strategy \\ :until_error)

  def sequence(data, :until_error) do
    Enum.reduce_while(data, {:ok, []}, fn value, acc ->
      payload = get_payload(value)
      acc_payload = get_payload(acc)

      if is_ok(value) and is_ok(acc) do
        {:cont, create_ok(prepend_nonempty(acc_payload, payload))}
      else
        {:halt, create_error(payload)}
      end
    end)
    |> reverse_payload()
  end

  @doc ~S"""
  Applies a function if data is successful (`{:ok, ...}`), otherwise returns the data as is

  ## Examples
  Most common `{:ok, value} | {:error, reason} | :error` case:
  ```elixir
  iex> greet = fn name -> "Hello, #{name}!" end

  iex> Monad.map({:ok, "John"}, greet)
  ...> {:ok, "Hello, John!"}

  iex> Monad.map({:error, :not_found}, greet)
  ...> {:error, :not_found}

  iex> Monad.map(:error, greet)
  ...> :error
  ```

  Tuples with more than one value are passed as tuple in the mapping function:
  ```elixir
  iex> Monad.map({:ok, "John", "John's info"}, fn {name, info} -> "Hello, #{name}! #{info}" end)
  ...> {:ok, "Hello, John! John's info"}
  ```
  """
  @spec map(result(), (any() -> any())) :: result()
  def map(data, fun) when is_ok(data) do
    data
    |> get_payload()
    |> fun.()
    |> create_ok()
  end

  def map(data, _fun) when is_error(data), do: data

  @doc ~S"""
  Applies a function if data is error, otherwise returns the data as is

  ## Examples
  ```elixir
  iex> Monad.map_error({:error, :not_found}, fn reason -> "Error: #{reason}" end)
  ...> {:error, "Error: not_found"}

  iex> Monad.map_error({:ok, "John"}, fn reason -> "Error: #{reason}" end)
  ...> {:ok, "John"}

  iex> Monad.map_error(:error, fn reason -> "Error: #{reason}" end)
  ...> :error
  ```
  """
  @spec map_error(result(), (any() -> any())) :: result()
  def map_error(data, fun) when is_error(data) do
    data
    |> get_payload()
    |> fun.()
    |> create_error()
  end

  def map_error(data, _fun) when is_ok(data), do: data

  @doc ~S"""
  Applies a function for value part of successful data, otherwise returns the data as is

  ## Examples
  ```elixir
  iex> Monad.flat_map({:ok, "John"}, fn name -> {:ok, "Hello, #{name}!"} end)
  ...> {:ok, "Hello, John!"}

  iex> Monad.flat_map({:error, :not_found}, fn reason -> {:ok, "Hello, #{reason}!"} end)
  ...> {:error, :not_found}

  iex> [{:ok, "John", 25}, {:ok, "Brother Tom", 30}]
  ...> |> Monad.flat_map(fn {name, age} -> {:ok, name, age * 2} end)
  ...> |> Monad.flat_map(fn {name, age} -> {:ok, "#{name} is #{age} years old"} end)
  ...> {:ok, ["John is 50 years old", "Brother Tom is 60 years old"]}

  iex> [{:ok, "John", 25}, {:error, :not_found}, {:ok, "Brother Tom", 30}]
  ...> |> Monad.flat_map(fn {name, age} -> {:ok, name, age * 2} end)
  ...> |> Monad.flat_map(fn {name, age} -> {:ok, "#{name} is #{age} years old"} end)
  ...> {:error, :not_found}
  ```
  """
  @spec flat_map(list(result()), (any() -> result())) :: result()
  def flat_map(data, fun) when is_list(data) do
    Enum.reduce_while(data, {:ok, []}, fn value, acc ->
      payload = get_payload(value)
      acc_payload = get_payload(acc)

      if is_ok(value) and is_ok(acc) do
        new_data = fun.(payload)
        if is_ok(new_data) do
          new_payload = get_payload(new_data)
          values = prepend_nonempty(acc_payload, new_payload)
          {:cont, create_ok(values)}
        else
          {:halt, new_data}
        end
      else
        {:halt, create_error(payload)}
      end
    end)
    |> reverse_payload()
  end

  def flat_map(data, fun) when is_ok(data) do
    payload = get_payload(data)
    fun.(payload)
  end

  def flat_map(data, _fun) when is_error(data), do: data

  @doc ~S"""
  Applies a function if data is successful (`{:ok, ...}`), otherwise applies another function

  Similar to `Monad.map/2`, but for both success and error cases

  ## Examples
  ```elixir
  iex> greet = fn name -> "Hello, #{name}!" end
  iex> error = fn reason -> "Error: #{reason}" end

  iex> Monad.bimap({:ok, "John"}, greet, error)
  ...> {:ok, "Hello, John!"}

  iex> Monad.bimap({:error, :not_found}, greet, error)
  ...> {:error, "Error: not_found"}
  ```
  """
  @spec bimap(result(), (any() -> any()), (any() -> any())) :: result()
  def bimap(data, success_fun, _error_fun) when is_ok(data) do
    data
    |> get_payload()
    |> success_fun.()
    |> create_ok()
  end

  def bimap(data, _success_fun, error_fun) when is_error(data) do
    data
    |> get_payload()
    |> error_fun.()
    |> create_error()
  end

  @doc ~S"""
  Calls a function with the data and returns the data as is

  ## Examples
  ```elixir
  iex> Monad.peek({:ok, "John"}, fn {:ok, name} -> IO.puts("Hello, #{name}!") end)
  ...> {:ok, "John"}

  iex> Monad.peek({:error, :not_found}, fn {:error, reason} -> IO.puts("Error: #{reason}") end)
  ...> {:error, :not_found}
  ```
  """
  @spec peek(result(), (any() -> any())) :: result()
  def peek(data, fun) do
    safe(fn -> fun.(data) end)

    data
  end

  @doc ~S"""
  Unwraps a data and returns the default value if the data is error

  ## Examples
  ```elixir
  iex> Monad.unwrap({:ok, "John"}, "Default")
  ...> "John"

  iex> Monad.unwrap({:error, :not_found}, "Default")
  ...> "Default"

  iex> Monad.unwrap(:error)
  ...> nil
  ```
  """
  @spec unwrap(result(), any()) :: any()
  def unwrap(data, default \\ nil)

  def unwrap(data, _default) when is_ok(data) do
    get_payload(data)
  end

  def unwrap(data, default) when is_error(data), do: default

  @doc ~S"""
  Unwraps a data, similar to `Monad.unwrap/2` but raises an error if the data is error

  ## Examples
  ```elixir
  iex> Monad.unwrap!({:ok, "John"})
  ...> "John"

  iex> Monad.unwrap!({:error, :not_found})
  ...> ** (RuntimeError) Error: not_found
  ```
  """
  @spec unwrap!(result()) :: any()
  def unwrap!(data) when is_ok(data) do
    get_payload(data)
  end

  def unwrap!(data), do: raise("Error: #{inspect(get_payload(data))}")

  @doc ~S"""
  Combines map and sequence functions

  ## Examples
  ```elixir
  iex> Monad.traverse(1..5, & {:ok, &1 * 2})   # map + sequence
  ...> {:ok, [2, 4, 6, 8, 10]}

  iex> map_even = fn x ->
         if rem(x, 2) == 0,
            do: {:ok, x * 2},
            else: {:error, :odd}
       end

  iex> Monad.traverse(1..5, map_even)
  ...> {:error, :odd}

  iex> Monad.traverse([2, 4, 6, 10], map_even)
  ...> {:ok, [4, 8, 12, 20]}
  ```
  """
  @spec traverse([result()] | result(), (any() -> result())) :: result()
  def traverse(data, fun) when is_ok(data) do
    payload = get_payload(data)
    result = fun.(payload)
    result
  end

  def traverse(data, _fun) when is_error(data), do: data

  def traverse(data, fun) do
    if Enumerable.impl_for(data) do
      do_traverse(data, fun)
    else
      data
    end
  end

  defp do_traverse(data, fun) do
    Enum.reduce_while(data, {:ok, []}, fn value, acc ->
      acc_payload = get_payload(acc)
      new_data = fun.(value)

      if is_ok(acc) and is_ok(new_data) do
        new_payload = get_payload(new_data)
        values = prepend_nonempty(acc_payload, new_payload)
        {:cont, create_ok(values)}
      else
        {:halt, new_data}
      end
    end)
    |> reverse_payload()
  end

  @doc ~S"""
  Checks if there is any error in the data, without nested values checking

  ## Examples
  ```elixir
  iex> Monad.any_error?({:ok, "John"})
  ...> false

  iex> Monad.any_error?([{:ok, "John"}, {:ok, "Brother Tom"}])
  ...> false

  iex> Monad.any_error?({:error, :not_found})
  ...> true

  iex> Monad.any_error?([{:error, :not_found}, {:ok, "John"}])
  ...> true
  ```
  """
  @spec any_error?([result()] | result()) :: boolean()
  def any_error?(data) when is_list(data) do
    Enum.any?(data, &is_error/1)
  end

  def any_error?(data) when is_ok(data), do: false
  def any_error?(data) when is_error(data), do: true

  @doc ~S"""
  Checks if all values are successful (`{:ok, ...}`), without nested values checking

  ## Examples
  ```elixir
  iex> Monad.all_ok?({:ok, "John"})
  ...> true

  iex> Monad.all_ok?([{:ok, "John"}, {:ok, "Brother Tom"}])
  ...> true

  iex> Monad.all_ok?([{:ok, "John"}, {:error, :not_found}])
  ...> false

  iex> Monad.all_ok?([{:ok, "John"}, {:error, :not_found}, {:ok, "Jane"}])
  ...> false
  ```
  """
  @spec all_ok?([result()] | result()) :: boolean()
  def all_ok?(data) when is_list(data) do
    Enum.all?(data, &is_ok/1)
  end

  def all_ok?(data) when is_ok(data), do: true
  def all_ok?(data) when is_error(data), do: false

  @doc ~S"""
  Wraps a function in a try/rescue block and returns `{:error, error}` if an error is raised

  Optionally accepts an `after_fun` that will be executed in the `after` block regardless of success or failure.

  ## Examples
  ```elixir
  iex> Monad.safe(fn -> 1 / 0 end)
  ...> {:error, %ArithmeticError{message: "bad argument in arithmetic expression"}}

  iex> Monad.safe(fn -> "Hello" end)
  ...> {:ok, "Hello"}

  iex> Monad.safe(fn -> "Success" end, fn -> IO.puts("Cleanup") end)
  ...> {:ok, "Success"}
  ```
  """
  @spec safe((() -> any()), (() -> any())) :: result()
  def safe(fun, after_fun \\ fn -> nil end) do
    try do
      {:ok, fun.()}
    rescue
      error -> {:error, error}
    catch
      _error, reason -> {:error, reason}
    after
      after_fun.()
    end
  end

  defp get_payload({_, value}), do: value
  defp get_payload(value) when is_tuple(value), do: Tuple.delete_at(value, 0)
  defp get_payload(_value), do: {}

  defp prepend_nonempty(list, {}), do: list
  defp prepend_nonempty(list, value), do: [value | list]

  defp create_error([]), do: :error
  defp create_error({}), do: :error
  defp create_error(value), do: {:error, value}

  defp create_ok([]), do: :ok
  defp create_ok({}), do: :ok
  defp create_ok(value), do: {:ok, value}

  defp reverse_payload({status, list}) when is_list(list), do: {status, Enum.reverse(list)}
  defp reverse_payload(value), do: value
end
