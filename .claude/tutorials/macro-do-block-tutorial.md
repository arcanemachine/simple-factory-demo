# Tutorial: Creating Macros with Do-Block Syntax (Without Manual `quote`)

## The Problem

When creating DSLs in Elixir, you often want users to write clean, intuitive code with do-blocks. However, beginners often struggle with requiring users to wrap their code in explicit `quote` blocks, which feels unnatural.

**Before (awkward, requires `quote`):**
```elixir
factory(
  name: :user,
  build: quote do
    def build_user(params \\ %{}) do
      %User{username: params[:username]}
    end
  end
)
```

**After (clean, no `quote`):**
```elixir
factory :user do
  %User{username: params[:username]}
end
```

## The Solution: Pattern Matching on Do-Blocks

The key insight is that **do-blocks are just keyword list syntax**. When you write:

```elixir
factory :user do
  # body
end
```

Elixir transforms this to:

```elixir
factory(:user, [do: body_ast])
```

So your macro can pattern match on this!

## Step-by-Step Implementation

### Step 1: Define the Macro Signature with Do-Block Pattern

```elixir
defmacro factory(name, do: body) do
  # name = the atom :user
  # body = the AST of everything inside the do block
end
```

This pattern matching automatically captures:
- `name`: The first argument (`:user`)
- `body`: The AST of the do-block content

### Step 2: Generate Function Names

```elixir
defmacro factory(name, do: body) do
  # Create function names based on the factory name
  build_function_name = :"build_#{name}"
  private_function_name = :"_#{build_function_name}_without_hooks"
  insert_function_name = :"insert_#{name}!"

  # Now generate code...
end
```

**Why?** We need to dynamically create function names like `build_user`, `build_post`, etc.

The `:"string"` syntax creates atoms from strings. So `:"build_#{name}"` when `name = :user` becomes `:build_user`.

### Step 3: Use `quote bind_quoted` to Inject Values

```elixir
defmacro factory(name, do: body) do
  build_function_name = :"build_#{name}"
  private_function_name = :"_#{build_function_name}_without_hooks"

  quote bind_quoted: [
    name: name,
    build_function_name: build_function_name,
    private_function_name: private_function_name,
    body: Macro.escape(body, unquote: true)
  ] do
    # Code that gets injected into the caller's module
  end
end
```

**Key concepts:**

1. **`quote bind_quoted:`** - This prevents accidental double evaluation of variables. Each variable in the list is evaluated once and bound.

2. **`Macro.escape(body, unquote: true)`** - This is THE CRITICAL PIECE:
   - `body` contains the AST from the do-block
   - `Macro.escape/2` prevents it from being evaluated in the macro context
   - `unquote: true` allows `unquote()` calls within the body to work correctly
   - Without this, your AST would get mangled!

### Step 4: Define Functions Using the Captured Body

Inside the `quote bind_quoted` block:

```elixir
quote bind_quoted: [
  build_function_name: build_function_name,
  private_function_name: private_function_name,
  body: Macro.escape(body, unquote: true)
] do
  # Create private function with the user's code
  defp unquote(private_function_name)(var!(params)) do
    unquote(body)  # <- Inject the do-block content here!
  end

  # Create public function that wraps it
  def unquote(build_function_name)(params \\ %{}) do
    params
    |> unquote(private_function_name)()  # Call the private function
  end
end
```

**Key concepts:**

1. **`unquote(private_function_name)`** - Injects the function name (`:_build_user_without_hooks`)
2. **`var!(params)`** - Makes `params` variable available to the injected body without hygiene
3. **`unquote(body)`** - Injects the user's do-block code here!

### Step 5: Make Variables Available with `var!`

Notice the use of `var!(params)`:

```elixir
defp unquote(private_function_name)(var!(params)) do
  unquote(body)
end
```

**Why `var!`?**

By default, variables in macros are hygienic (isolated). But we WANT the user's code in the do-block to access `params`. The `var!` macro bypasses hygiene, making `params` available.

When the user writes:

```elixir
factory :user do
  %User{username: params[:username]}  # <- needs to access 'params'
end
```

The `params` in their code refers to the argument we defined with `var!(params)`.

## Complete Working Example

Here's a minimal complete implementation:

```elixir
defmodule MyFactory do
  defmacro factory(name, do: body) do
    build_function_name = :"build_#{name}"

    quote bind_quoted: [
      build_function_name: build_function_name,
      body: Macro.escape(body, unquote: true)
    ] do
      def unquote(build_function_name)(var!(params) \\ %{}) do
        unquote(body)
      end
    end
  end
end

# Usage:
defmodule UserFactory do
  require MyFactory
  import MyFactory

  factory :user do
    %User{
      id: params[:id],
      username: params[:username] || "default-user"
    }
  end
end

# This generates:
# def build_user(params \\ %{}) do
#   %User{
#     id: params[:id],
#     username: params[:username] || "default-user"
#   }
# end
```

## Advanced: The Full FactoryMan Pattern

The actual FactoryMan implementation adds:

1. **Hooks system** - Wrap the private function with before/after hooks
2. **Insert function** - Generate database insertion function
3. **Module attributes** - Read configuration from `@factory_opts`

```elixir
defmacro factory(name, do: body) do
  build_function_name = :"build_#{name}"
  private_function_name = :"_#{build_function_name}_without_hooks"
  insert_function_name = :"insert_#{name}!"

  quote bind_quoted: [
    name: name,
    build_function_name: build_function_name,
    private_function_name: private_function_name,
    insert_function_name: insert_function_name,
    body: Macro.escape(body, unquote: true)
  ] do
    # Get configuration from module attribute
    factory_opts = Module.get_attribute(__MODULE__, :factory_opts)
    hooks = factory_opts[:hooks] || []
    repo = factory_opts[:repo]

    # Private function (no hooks)
    defp unquote(private_function_name)(var!(params)) do
      unquote(body)
    end

    # Public build function (with hooks)
    def unquote(build_function_name)(params \\ %{}) do
      params
      |> then(&FactoryMan.get_hook_handler(unquote(hooks), :before_build).(&1))
      |> unquote(private_function_name)()
      |> then(&FactoryMan.get_hook_handler(unquote(hooks), :after_build).(&1))
    end

    # Insert function (if repo configured)
    if not is_nil(repo) do
      def unquote(insert_function_name)(params \\ %{}) do
        params
        |> unquote(build_function_name)()
        |> then(&FactoryMan.get_hook_handler(unquote(hooks), :before_insert).(&1))
        |> unquote(repo).insert!()
        |> then(&FactoryMan.get_hook_handler(unquote(hooks), :after_insert).(&1))
      end
    end
  end
end
```

## Key Takeaways

1. **Do-blocks are keyword lists** - `factory :user do ... end` becomes `factory(:user, do: ...)`

2. **Pattern match on `do: body`** - Capture the block content as AST

3. **Use `Macro.escape(body, unquote: true)`** - Preserve the AST for later injection

4. **Use `quote bind_quoted`** - Safely inject computed values

5. **Use `unquote(body)`** - Inject the user's code into generated functions

6. **Use `var!(params)`** - Make variables available across hygiene boundaries

## Common Pitfalls

❌ **Forgetting `Macro.escape`**
```elixir
quote bind_quoted: [body: body] do  # Wrong! AST gets mangled
  unquote(body)
end
```

✅ **Using `Macro.escape`**
```elixir
quote bind_quoted: [body: Macro.escape(body, unquote: true)] do
  unquote(body)
end
```

❌ **Not using `var!` for shared variables**
```elixir
def unquote(name)(params) do  # params not available to body
  unquote(body)
end
```

✅ **Using `var!` to share variables**
```elixir
def unquote(name)(var!(params)) do  # params IS available to body
  unquote(body)
end
```

## Further Reading

- [Elixir Macro module docs](https://hexdocs.pm/elixir/Macro.html)
- [Metaprogramming Elixir book](https://pragprog.com/titles/cmelixir/metaprogramming-elixir/)
- [Understanding `quote` and `unquote`](https://elixir-lang.org/getting-started/meta/quote-and-unquote.html)
