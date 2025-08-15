# Monaditto

> *"Finally, monads in Elixir that don't make you want to become a JavaScript developer"*

A pragmatic monad library for Elixir that works with your existing `{:ok, value} | {:error, reason}` code. No fancy wrapper types, no category theory PhD required, just good old Elixir tuples doing monad things.

## Why though?

You're already using monads every day in Elixir:

```elixir
jose = %{first_name: "Jose", last_name: "Valim"}
{:ok, "Jose"} = Map.fetch(jose, :first_name)    # Maybe monad says hello
:error = Map.fetch(jose, :age)                  # Maybe monad says goodbye
```

But then you end up with code like this:

```elixir
case fetch_user(id) do
  {:ok, user} ->
    case get_email(user) do
      {:ok, email} ->
        case send_notification(email) do
          {:ok, result} -> {:ok, result}
          {:error, reason} -> {:error, reason}
        end
      {:error, reason} -> {:error, reason}
    end
  {:error, reason} -> {:error, reason}
end
```

Of course, you can make some improvements:
```elixir
with {:ok, user} <- fetch_user(id),
     {:ok, email} <- get_email(user) do
  send_notification(email)
end
```

But with `Monaditto` you can rock it even better!

*Narrator: "There had to be a better way."*

## The Better Way™

```elixir
user_id
|> fetch_user()                    # {:ok, %User{}} | {:error, :not_found}
|> Monad.map(&get_email/1)         # {:ok, "user@example.com"} | {:error, :not_found}
|> Monad.map(&send_notification/1) # {:ok, :sent} | {:error, :not_found}
```

Clean, readable, and your error handling is automagically short-circuited. Like `with` statements, but with more style points.

## Installation

Add `monaditto` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:monaditto, "~> 0.1.0"}
  ]
end
```

## Quick Start

```elixir
import Monad

# Basic mapping
{:ok, "hello"}
|> map(&String.upcase/1)
|> map(&String.reverse/1)
# => {:ok, "OLLEH"}

# Error short-circuiting
{:error, :oops}
|> map(&String.upcase/1)  # Nope, not happening
|> map(&String.reverse/1) # Still nope
# => {:error, :oops}

# Safe operations
safe(fn -> 1 / 0 end)
# => {:error, %ArithmeticError{...}}

# Processing lists
[{:ok, 1}, {:ok, 2}, {:ok, 3}]
|> traverse(&({:ok, &1 * 2}))
# => {:ok, [2, 4, 6]}
```

## Available Functions

- `map/2` - Transform success values
- `map_error/2` - Transform error values
- `flat_map/2` - Chain operations that return results
- `bimap/3` - Transform both success and error cases
- `peek/2` - Side effects without changing the value
- `traverse/2` - Map and sequence combined
- `sequence/2` - Unwrap lists of results
- `safe/2` - Wrap dangerous operations
- `unwrap/2` & `unwrap!/1` - Extract values (carefully)
- `any_error?/1` & `all_ok?/1` - Validation helpers

## Philosophy

This library embraces Elixir's "let it crash" mentality while giving you tools to handle errors gracefully when you need to. We're not trying to turn Elixir into Haskell (though Haskell is lovely). We're just making your existing error-handling patterns more composable and less nested.

No magic, no surprises, just functions that do what they say on the tin.

## Documentation

Full documentation is available at [HexDocs](https://hexdocs.pm/monaditto) (when we publish it).

## Contributing

Found a bug? Have an idea? PRs welcome! Just remember: keep it simple, keep it pragmatic, keep it Elixir-y.

## License

MIT License. Because sharing is caring, and lawyers are expensive.

---

*Made with ❤️ and a healthy dose of functional programming enthusiasm*