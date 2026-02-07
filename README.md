# FactoryMan

Factory definitions for Elixir test suites.

FactoryMan provides a simple, flexible way to create test data with automatic struct building, database insertion, and customizable hooks.

## Installation

Add FactoryMan to your `mix.exs` dependencies:

```elixir
def deps do
  [
    {:factory_man, "0.1.0"}
  ]
end
```

Then run `mix deps.get`.

## Quick Start

Create a factory module:

```elixir
defmodule MyApp.Factories.Users do
  use FactoryMan, repo: MyApp.Repo

  alias MyApp.Users.User

  deffactory user(params \\ %{}), struct: User do
    base_params = %{username: "user-#{System.os_time()}"}

    Map.merge(base_params, params)
  end
end
```

Build and insert in tests:

```elixir
# Build a struct (not persisted)
user = MyApp.Factories.Users.build_user_struct(%{username: "test_user"})
# => %User{id: nil, username: "test_user"}

# Insert into database
user = MyApp.Factories.Users.insert_user!(%{username: "test_user"})
# => %User{id: 1, username: "test_user"}

# Insert multiple records
users = MyApp.Factories.Users.insert_user_list!(3)
# => [%User{id: 1, ...}, %User{id: 2, ...}, %User{id: 3, ...}]
```

## Features

- **Automatic struct building** - Define Ecto schemas and FactoryMan handles the rest
- **Database insertion** - Built-in `insert_` functions with configurable repo
- **List factories** - Create multiple records with `*_list` functions
- **Sequence generation** - Automatic unique value generation for usernames, emails, etc.
- **Lazy evaluation** - Compute values at build time with 0 or 1 arity functions
- **Factory composition** - Extend factories and nest them for complex associations
- **Hooks** - Transform data at build, insert, or any stage with custom hooks

## Documentation

Full documentation is available in the `FactoryMan` module:

- Basic factory creation and usage
- List factories for bulk data creation
- Sequence generation for unique values
- Lazy evaluation for computed attributes
- Factory inheritance with the `:extends` option
- Hooks for custom transformation logic

## License

MIT License - see [LICENSE.md](LICENSE.md)
