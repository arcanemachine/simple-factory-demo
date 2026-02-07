defmodule FactoryMan do
  @moduledoc """
  Test data factories with automatic struct building, database insertion, and customizable hooks.

  ## Usage

  Create a factory module with struct factories for Ecto schemas you need to persist:

      defmodule MyApp.Factories.Users do
        use FactoryMan, repo: MyApp.Repo

        alias MyApp.Users.User

        deffactory user(params \\ %{}), struct: User do
          base_params = %{username: "user-#{System.os_time()}"}

          Map.merge(base_params, params)
        end
      end

  Create non-struct factories for data that never touches the database, like API payloads or
  config maps:

      defmodule MyApp.Factories.Helpers do
        use FactoryMan

        deffactory api_payload(params \\ %{}) do
          base_params = %{
            data: "value",
            timestamp: DateTime.utc_now()
          }

          Map.merge(base_params, params)
        end
      end

  **Struct factories** (with `struct:` option) generate:

      build_user_params/0, build_user_params/1       # Build params map
      build_user_struct/0, build_user_struct/1         # Build struct (not persisted)
      insert_user!/0, insert_user!/1, insert_user!/2   # Insert into database

      # List variants
      build_user_params_list/1, build_user_params_list/2
      build_user_struct_list/1, build_user_struct_list/2
      insert_user_list!/1, insert_user_list!/2, insert_user_list!/3

  **Non-struct factories** (without `struct:` option) generate:

      build_api_payload_params/0, build_api_payload_params/1  # Build params map only
      build_api_payload_params_list/1, build_api_payload_params_list/2

  ## Defining Factories

  The `deffactory` macro works like defining a function. You specify the factory name and a single
  parameter (e.g. `param`), with an optional default value (e.g. `%{}`):

      deffactory user(params \\ %{}), struct: User do
        base_params = %{username: "user-#{System.os_time()}"}

        Map.merge(base_params, params)
      end

  You can name the parameter whatever you want:

      deffactory user(attrs \\ %{}), struct: User do
        base_attrs = %{username: "user-#{System.os_time()}"}

        Map.merge(base_attrs, attrs)
      end

  **Required parameters** (no default) when no default fallback is desired:

      deffactory user_from_config(config), struct: User do
        # Factory won't compile without config argument
        base_params = %{username: config[:username] || "default"}

        Map.merge(base_params, config)
      end

  **Building factories on other factories:**

  Call other factory functions within a factory definition to automatically create required
  associations:

      deffactory author(params \\ %{}), struct: Author do
        base_params = %{
          name: "Test Author",
          # Automatically build associated user if not provided
          user: params[:user] || build_user_struct()
        }

        Map.merge(base_params, params)
      end

  Extend and customize existing factories:

      deffactory user(params \\ %{}), struct: User do
        base_params = %{username: "user-#{System.os_time()}"}

        Map.merge(base_params, params)
      end

      deffactory admin(params \\ %{}), struct: User do
        # Reuse user factory, override role
        base_params = %{role: "admin"}

        params
        |> build_user_params()    # Get base user params
        |> Map.merge(base_params) # Add admin overrides
        |> Map.merge(params)      # Apply caller overrides
      end

  ## Factory Options

  Options cascade from parent module to child module to individual factory, letting you configure
  behavior at whichever level is right for you:

  **Module-level options** (set with `use FactoryMan`):
  - `:repo` - Ecto repo for database operations (required for insert functions)
  - `:extends` - Parent factory module to inherit common configuration
  - `:hooks` - Hooks applied to all factories in the module

  **Factory-level options** (set with `deffactory`):
  - `:struct` - Ecto schema struct to build (generates struct and insert functions)
  - `:insert?` - Set to `false` to prevent accidental database insertion (e.g., for read-only test
  data)
  - `:build_struct?` - Set to `false` when you only need raw params (e.g., for API request bodies)
  - `:hooks` - Additional hooks merged with module-level hooks

  ## Factory Inheritance

  Use inheritance to avoid repeating common configuration across multiple factory modules:

      defmodule MyApp.Factory do
        use FactoryMan, repo: MyApp.Repo

        def generate_username, do: "user-#{System.os_time()}"
      end

  Child factories inherit the parent's repo, hooks, and helper functions via `:extends`:

      defmodule MyApp.Factories.Users do
        use FactoryMan, extends: MyApp.Factory

        deffactory user(params \\ %{}), struct: User do
          %{username: generate_username()} |> Map.merge(params)
        end
      end

  **Options cascade through all levels:**
  Parent module options → Child module options → Individual factory options.
  Later options override earlier ones, letting you customize at any level.

      defmodule MyApp.Factory do
        use FactoryMan,
          repo: MyApp.Repo,
          hooks: [after_insert: &reset_assocs/1]
      end

      defmodule MyApp.Factories.Users do
        use FactoryMan,
          extends: MyApp.Factory,
          hooks: [before_build_params: &log_build/1]  # Merged with parent hooks

        # Inherits :repo and both hooks from MyApp.Factory
        deffactory user(params \\ %{}), struct: User do
          base_params = %{username: "user-#{System.os_time()}"}

          Map.merge(base_params, params)
        end

        # Override hooks for this specific factory only
        deffactory admin(params \\ %{}), struct: User, hooks: [after_insert: &promote_to_admin/1] do
          base_params = %{username: "admin-#{System.os_time()}"}

          Map.merge(base_params, params)
        end

        # Disable insert for this factory (build only)
        deffactory draft_user(params \\ %{}), struct: User, insert?: false do
          base_params = %{username: "draft-#{System.os_time()}"}

          Map.merge(base_params, params)
        end

        # Disable struct building (params only)
        deffactory user_config(params \\ %{}), struct: User, build_struct?: false do
          base_params = %{theme: "dark", notifications: true}

          Map.merge(base_params, params)
        end
      end

  ## List Factories

  Create multiple records:

      # Build 3 structs
      MyApp.Factories.Users.build_user_struct_list(3)
      # => [%User{id: nil, ...}, %User{id: nil, ...}, %User{id: nil, ...}]

      # Insert 3 users
      MyApp.Factories.Users.insert_user_list!(3)
      # => [%User{id: 1, ...}, %User{id: 2, ...}, %User{id: 3, ...}]

      # With custom params
      MyApp.Factories.Users.insert_user_list!(2, %{role: "admin"}, returning: true)

  Each item is evaluated independently, so timestamps and sequences generate unique values.

  ## Sequence Generation

  Generate unique values across test runs:

  Basic sequences:

      deffactory user(params \\ %{}), struct: User do
        base_params = %{username: sequence("user")}  # user0, user1, user2...

        Map.merge(base_params, params)
      end

  Custom formatters:

      deffactory user(params \\ %{}), struct: User do
        base_params = %{
          email: sequence(:email, fn n -> "user\#{n}@example.com" end)
        }

        Map.merge(base_params, params)
      end

  Cyclical sequences:

      deffactory user(params \\ %{}), struct: User do
        base_params = %{
          role: sequence(:role, ["admin", "moderator", "user"])
        }

        Map.merge(base_params, params)
      end

  Custom starting value:

      deffactory order(params \\ %{}), struct: Order do
        base_params = %{
          order_number: sequence(:order, fn n -> "ORD-\#{n}" end, start_at: 1000)
        }

        Map.merge(base_params, params)
      end

  Reset sequences in test setup for predictable values:

      setup do
        FactoryMan.Sequence.reset()
        :ok
      end

  ## Lazy Evaluation

  Functions in factory params are evaluated at build time:

      deffactory user(params \\ %{}), struct: User do
        base_params = %{
          username: "user-#{System.os_time()}",
          # 0-arity: called with no arguments
          created_at: fn -> DateTime.utc_now() end,
          # 1-arity: receives the parent factory
          display_name: fn user -> "\#{user.username} (User)" end
        }

        Map.merge(base_params, params)
      end

  ## Hooks

  Transform data at specific stages. Every factory action has both a `before` and `after` hook,
  letting you intercept and modify data at the exact point you need:

  | Action               | Before Hook            | After Hook            |
  | -------------------- | ---------------------- | --------------------- |
  | Build params         | `:before_build_params` | `:after_build_params` |
  | Build struct         | `:before_build_struct` | `:after_build_struct` |
  | Insert into database | `:before_insert`       | `:after_insert`       |

  Example: Reset loaded associations after insert to match a fresh database query:

      defmodule MyApp.Factory do
        use FactoryMan,
          repo: MyApp.Repo,
          hooks: [after_insert: &__MODULE__.reset_assocs/1]

        def reset_assocs(struct) do
          Ecto.reset_fields(struct, struct.__struct__.__schema__(:associations))
        end
      end

  ## Embedded Schemas

  Factories for embedded schemas work like regular struct factories but without database
  insertion:

      defmodule MyApp.Factories.Settings do
        use FactoryMan, extends: MyApp.Factory

        alias MyApp.Users.Settings

        deffactory settings(params \\ %{}), struct: Settings do
          base_params = %{
            theme: "dark",
            notifications: true
          }

          Map.merge(base_params, params)
        end
      end

  Embedded schemas generate `build_*_params` and `build_*_struct` functions only (as well as
  the matching `*_list` functions), but do not generate any `insert_*` functions.

  ## Debugging

  FactoryMan generates debug functions showing configured options:

      iex> MyApp.Factory._factory_opts()
      [repo: MyApp.Repo]

      iex> MyApp.Factories.Users._user_factory_opts()
      [repo: MyApp.Repo, struct: User]
  """

  defmacro __using__(opts \\ []) do
    quote do
      import unquote(__MODULE__),
        only: [deffactory: 2, deffactory: 3, sequence: 1, sequence: 2, sequence: 3]

      parent_factory_opts =
        case unquote(opts)[:extends] do
          nil ->
            # Use opts from current factory only
            unquote(opts)

          extends ->
            # Extend base factory opts
            parent_opts = extends.__info__(:attributes)[:parent_factory_opts] || []

            Keyword.merge(parent_opts, unquote(opts))
        end

      # Put factory module options into a module attribute that can be read by the child factories
      Module.register_attribute(__MODULE__, :parent_factory_opts, persist: true)
      Module.put_attribute(__MODULE__, :parent_factory_opts, parent_factory_opts)

      @doc """
      A debug helper function that can show all the options for the `#{inspect(__MODULE__)}`
      factory module.
      """
      def _factory_opts, do: @parent_factory_opts
    end
  end

  defmacro deffactory(factory_head, opts \\ [], do: block) do
    # Extract factory name, the arg AST (preserving any default), and the user's var
    {factory_name, arg_ast, user_var} =
      case factory_head do
        {name, _, [{:\\, _, [{var, _, _}, _]} = arg_ast]} -> {name, arg_ast, Macro.var(var, nil)}
        {name, _, [{var, _, _} = arg]} -> {name, arg, Macro.var(var, nil)}
      end

    quote bind_quoted: [
            factory_name: factory_name,
            arg_ast: Macro.escape(arg_ast, unquote: true),
            user_var: Macro.escape(user_var, unquote: true),
            opts: opts,
            block: Macro.escape(block, unquote: true)
          ] do
      parent_factory_opts = Module.get_attribute(__MODULE__, :parent_factory_opts)

      parent_factory_hooks = Keyword.get(parent_factory_opts, :hooks, [])
      child_factory_hooks = Keyword.get(opts, :hooks, [])
      merged_hooks = Keyword.merge(parent_factory_hooks, child_factory_hooks)

      merged_opts = Keyword.merge(parent_factory_opts, opts) |> Keyword.merge(merged_hooks)

      @doc "A debug helper function that shows all options for the `#{factory_name}` factory."
      def unquote(String.to_atom("_#{factory_name}_factory_opts"))(), do: unquote(merged_opts)

      build_struct? = merged_opts[:build_struct?]
      hooks = merged_hooks
      insert? = merged_opts[:insert?]
      repo = merged_opts[:repo]
      struct = merged_opts[:struct]

      # Generate params builder function - builds head inline from shared arg_ast
      def unquote({:"build_#{factory_name}_params", [], [arg_ast]}) do
        unquote(user_var) =
          FactoryMan.get_hook_handler(unquote(hooks), :before_build_params).(unquote(user_var))

        unquote(block)
        |> FactoryMan.evaluate_lazy_attributes()
        |> then(&FactoryMan.get_hook_handler(unquote(hooks), :after_build_params).(&1))
      end

      # Generate params list builder function
      # List factory approach inspired by ExMachina's build_list/insert_list functions
      # See: https://github.com/thoughtbot/ex_machina
      def unquote(:"build_#{factory_name}_params_list")(count)
          when is_integer(count) and count >= 0 do
        unquote(:"build_#{factory_name}_params_list")(count, %{})
      end

      def unquote(:"build_#{factory_name}_params_list")(count, params)
          when is_integer(count) and count >= 0 and is_map(params) do
        Stream.repeatedly(fn -> unquote(:"build_#{factory_name}_params")(params) end)
        |> Enum.take(count)
      end

      if struct != nil and build_struct? != false do
        # Generate struct builder function - builds head inline from shared arg_ast
        def unquote({:"build_#{factory_name}_struct", [], [arg_ast]}) do
          unquote(user_var)
          |> unquote(:"build_#{factory_name}_params")()
          |> then(&FactoryMan.get_hook_handler(unquote(hooks), :before_build_struct).(&1))
          |> then(&struct!(unquote(struct), &1))
          |> then(&FactoryMan.get_hook_handler(unquote(hooks), :after_build_struct).(&1))
        end

        # Generate struct list builder function
        # List factory approach inspired by ExMachina's build_list/insert_list functions
        # See: https://github.com/thoughtbot/ex_machina
        def unquote(:"build_#{factory_name}_struct_list")(count)
            when is_integer(count) and count >= 0 do
          unquote(:"build_#{factory_name}_struct_list")(count, %{})
        end

        def unquote(:"build_#{factory_name}_struct_list")(count, params)
            when is_integer(count) and count >= 0 and is_map(params) do
          Stream.repeatedly(fn ->
            unquote(:"build_#{factory_name}_struct")(params)
          end)
          |> Enum.take(count)
        end

        is_insertable_ecto_schema_factory? =
          ((not is_nil(repo) and Code.ensure_compiled!(struct)) &&
             function_exported?(struct, :__schema__, 1)) and struct.__schema__(:source) != nil

        if is_insertable_ecto_schema_factory? and insert? != false do
          # Generate struct insert functions - builds head inline from shared arg_ast
          def unquote({:"insert_#{factory_name}!", [], [arg_ast]})

          def unquote(:"insert_#{factory_name}!")(repo_insert_opts)
              when is_list(repo_insert_opts) do
            unquote(:"insert_#{factory_name}!")(%{}, repo_insert_opts)
          end

          def unquote(:"insert_#{factory_name}!")(unquote(user_var)) do
            unquote(:"insert_#{factory_name}!")(unquote(user_var), [])
          end

          def unquote(:"insert_#{factory_name}!")(
                unquote(user_var),
                repo_insert_opts
              )
              when is_list(repo_insert_opts) do
            unquote(user_var)
            |> unquote(:"build_#{factory_name}_struct")()
            |> then(&FactoryMan.get_hook_handler(unquote(hooks), :before_insert).(&1))
            |> unquote(repo).insert!(repo_insert_opts)
            |> then(&FactoryMan.get_hook_handler(unquote(hooks), :after_insert).(&1))
          end

          # Generate struct insert list functions
          def unquote(:"insert_#{factory_name}_list!")(count)
              when is_integer(count) and count >= 0 do
            unquote(:"insert_#{factory_name}_list!")(count, %{}, [])
          end

          def unquote(:"insert_#{factory_name}_list!")(count, repo_insert_opts)
              when is_integer(count) and count >= 0 and is_list(repo_insert_opts) do
            unquote(:"insert_#{factory_name}_list!")(count, %{}, repo_insert_opts)
          end

          def unquote(:"insert_#{factory_name}_list!")(count, params)
              when is_integer(count) and count >= 0 and is_map(params) do
            unquote(:"insert_#{factory_name}_list!")(count, params, [])
          end

          def unquote(:"insert_#{factory_name}_list!")(count, params, repo_insert_opts)
              when is_integer(count) and count >= 0 and is_map(params) and
                     is_list(repo_insert_opts) do
            Stream.repeatedly(fn ->
              unquote(:"insert_#{factory_name}!")(params, repo_insert_opts)
            end)
            |> Enum.take(count)
          end
        end
      end
    end
  end

  @doc """
  Evaluate lazy attributes in a map or struct.

  Functions with 0 arity are called with no arguments.
  Functions with 1 arity receive the parent factory as their argument.

  ## Examples

      iex> FactoryMan.evaluate_lazy_attributes(%{name: "test", timestamp: fn -> 12345 end})
      %{name: "test", timestamp: 12345}

      iex> FactoryMan.evaluate_lazy_attributes(%{first: "John", last: fn attrs -> attrs.first <> " Smith" end})
      %{first: "John", last: "John Smith"}
  """
  @spec evaluate_lazy_attributes(struct | map) :: struct | map
  def evaluate_lazy_attributes(%{__struct__: record} = factory) do
    struct!(
      record,
      factory |> Map.from_struct() |> do_evaluate_lazy_attributes(factory)
    )
  end

  def evaluate_lazy_attributes(attrs) when is_map(attrs) do
    do_evaluate_lazy_attributes(attrs, attrs)
  end

  defp do_evaluate_lazy_attributes(attrs, parent_factory) do
    attrs
    |> Enum.map(fn
      {k, v} when is_function(v, 1) -> {k, v.(parent_factory)}
      {k, v} when is_function(v) -> {k, v.()}
      {_, _} = tuple -> tuple
    end)
    |> Enum.into(%{})
  end

  @doc """
  The default handler for hooks. This function is a no-op, and simply returns the given `value`
  without any modifications.

  ## Examples

      iex> FactoryMan.fallback_hook_handler(123)
      123
  """
  def fallback_hook_handler(value), do: value

  @doc """
  Get the configured handler for a `hook`, or fall back to `&FactoryMan.fallback_hook_handler/0`.

  ## Examples

      iex> hooks = [after_insert: &YourProject.Factories.Users.user_after_insert_handler/1]

      iex> FactoryMan.get_hook_handler(hooks, :before_build)
      &FactoryMan.fallback_hook_handler/0

      iex> FactoryMan.get_hook_handler(hooks, :after_insert)
      &YourProject.Factories.Users.user_after_insert_handler/1
  """
  def get_hook_handler(hooks, hook), do: hooks[hook] || (&FactoryMan.fallback_hook_handler/1)

  @doc """
  Generates a sequence of strings.

  The sequence name is used as the beginning of the string. For example, if you
  do `sequence("joe")`, you will get back `"joe0"`, then `"joe1"`, and so on.

  ## Example

      def user_factory do
        %{
          username: sequence("joe")
        }
      end

  If you want to customize the returned string you can use `sequence/2`.
  """

  @spec sequence(String.t()) :: String.t()
  def sequence(name), do: FactoryMan.Sequence.next(name)

  @doc """
  Generates and returns a unique sequence.

  If a formatter function is passed, it will be called with the current
  position of the sequence. You can also pass a list, and each item in the list
  will be returned in sequence.

  ## Example with a formatter function

      def user_factory do
        %{
          email: sequence(:email, fn n -> "me-\#{n}@foo.com" end)
        }
      end

  ## Example with a list

      def user_factory do
        %{
          name: sequence(:name, ["Joe", "Mike", "Sarah"])
        }
      end
  """

  @spec sequence(any, (integer -> any) | nonempty_list) :: any
  def sequence(name, formatter), do: FactoryMan.Sequence.next(name, formatter)

  @doc """
  Generates and returns a unique sequence with options.

  Currently, the only option is `:start_at` which specifies the number to
  start the sequence at.

  ## Example

      def money_factory do
        %{
          cents: sequence(:cents, fn n -> "\#{n}" end, start_at: 600)
        }
      end
  """

  @spec sequence(any, (integer -> any) | nonempty_list, start_at: non_neg_integer) :: any
  def sequence(name, formatter, opts), do: FactoryMan.Sequence.next(name, formatter, opts)
end
