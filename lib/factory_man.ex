defmodule FactoryMan do
  @moduledoc """
  Create and customize test factories for generating synthetic data during tests.

  ## Getting started

  - Install the application:

  `your_project/mix.exs`
  ```elixir
  FIXME
  ```

  - If using `FactoryMan.Sequence`, add the following line to `test/test_helper.exs`:

  `your_project/test/test_helper.exs`
  ```elixir
  FIXME
  ```

  ### Create your first factory

  Create a factory module in the desired location:

  `your_project/test/support/factories/users.exs`
  ```elixir
  defmodule YourProject.Factories.Users do
    use FactoryMan, repo: YourProject.Repo

    alias YourProject.Users.Profile
    alias YourProject.Users.User

    factory(
      name: :user,
      build:
        def build_user(params \\ %{}) do
          %User{
            id: params[:id],
            username: Map.get(params, :username, "user-#{System.os_time(:second)}")
          }
        end
    )

    factory(
      name: :user,
      build:
        (
          @doc "You can add docstrings for your builder functions, if desired."
          def build_profile(params \\ %{}) do
            %Profile{
              id: params[:id],
              user: Map.get(params, :user, build_user(params[:user]))
            }
          end
        )
    )
  end
  ```

  Now, you can use this factory in the configured environment(s):

  ```elixir
  iex> built_user = YourProject.Factories.Users.build_user(%{username: "some_user"})
  %YourProject.Users.User{id: nil, username: "some_user"}

  iex> inserted_user = YourProject.Factories.Users.insert_user!(%{username: "some_user"})
  %YourProject.Users.User{id: 1, username: "some_user"}

  iex> inserted_profile_1 = YourProject.Factories.Users.insert_profile!()
  %YourProject.Users.Profile{id: 1, user: %YourProject.Users.User{id: 2}}

  iex> inserted_profile_2 = YourProject.Factories.Users.insert_profile!(%{user: inserted_user})
  %YourProject.Users.Profile{id: 1, user: %YourProject.Users.User{id: 1, username: "some_user"}}
  ```

  ## Factory module options

  #### `:after_insert` (arity-1 function reference) - A post-insert hook for your factory products

  Perform actions on your factory products after they have been inserted to the database:

  - Create a handler function:

  ```elixir
  FIXME
  ```

  - The handler will be automatically invoked after the factory product has been inserted into
  the database:

  ```elixir
  FIXME
  ```

  #### `:debug?` (boolean) - Add debug info functions

  This option will produce a debug helper function for each factory (both for the whole module,
  and for each factory macro) which shows all options that have been passed into the factory. This
  function may be useful during debugging.

  `your_project/test/support/factory.ex`
  ```
  defmodule YourProject.Factory do
    use FactoryMan, repo: YourProject.Repo, debug?: true

    factory(name: :something, build: def(build_something(_ \\ 0), do: :something), insert?: false)
  end
  ```

  ```elixir
  iex> YourProject.Factory.something_opts()
  [repo: YourProject.Repo, name: :something, build: {:build_something, 1}, insert?: false]

  #### `:extends` (module) - Reduce boilerplate by inheriting options from a parent factory

  You are encouraged (but not required) to create a "base" factory, which can be extended to
  produce "child" factories (which inherit the options set in the parent factory/ies):

  - Create a base factory:

  `your_project/test/support/factory.ex`
  ```
  defmodule YourProject.Factory do
    use FactoryMan, repo: YourProject.Repo

    # You may also define common factory helper functions in this module

    @doc "Generate a random string of a given `length`."
    def generate_random_string(length),
      do: crypto.strong_rand_bytes(length) |> Base.encode64() |> String.slice(0, length)
  end
  ```

  - When creating a child factory, use the `:extends` option to extend the base factory:

  `your_project/test/support/factories/users.ex`
  ```
  defmodule YourProject.Factories.Users do
    use FactoryMan, extends: YourProject.Factory

    alias YourProject.Factory
    alias YourProject.Users.User

    factory(
      name: :user,
      build:
        def build_user(params \\ %{}) do
          %User{
            id: params[:id],
            username: Map.get(params, :username, Factory.generate_random_string(12))
          }
        end
    )
  end
  ```

  ## Factory conventions

  > NOTE: These conventions are guidelines, not rules.

  - You should define base factories in the singular namespace (e.g. `YourProject.Factory`), and
  child factories in the plural namespace (e.g. `YourProject.Factories.Users`).
    - For more info on "base" and "child" factories, see the section `:extends` option.

  - If you are not using "base" and "child" factories, then you should only use the plural
  namespace (e.g. `YourProject.Factories.Users`).

  - Create a separate factory for each context. Your factory module hierarchy should match your
  context module hierarchy. For example, if you have a context `YourProject.Users`, you should
  have a factory called `YourProject.Factories.Users`.

  ## Common recipes

  FIXME: Add common recipes here (e.g. Add assocs, assoc attrs, etc.)
  """

  defmacro __using__(opts \\ []) do
    quote do
      # Import factory macro
      import unquote(__MODULE__), only: [factory: 1]

      factory_opts =
        case unquote(opts)[:extends] do
          nil ->
            # Use opts from current factory only
            unquote(opts)

          extends ->
            # Extend base factory opts
            parent_opts = extends.__info__(:attributes)[:factory_opts] || []

            Keyword.merge(parent_opts, unquote(opts))
        end

      # Put factory options into a module attribute that can be read by the child factories
      Module.register_attribute(__MODULE__, :factory_opts, persist: true)
      Module.put_attribute(__MODULE__, :factory_opts, factory_opts)

      if @factory_opts[:debug?] do
        @doc "A debug helper function that can show all the options used in this factory module."
        def factory_opts, do: @factory_opts
      end
    end
  end

  defmacro factory(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      factory_opts = Module.get_attribute(__MODULE__, :factory_opts)

      opts =
        factory_opts
        # Drop keys that do not pertain to individual factories
        |> Keyword.drop([:debug?, :extends])
        |> Keyword.merge(opts)

      repo = opts[:repo]
      factory_name = Keyword.fetch!(opts, :name)

      if factory_opts[:debug?] do
        @doc "A debug helper function that shows all the options used in this factory."
        def unquote(String.to_atom("#{factory_name}_opts"))(),
          do: unquote(opts)
      end

      # Build
      {build_function_name, _build_function_arity} =
        case opts[:build] do
          nil -> raise "the `:build` option must be a function"
          _ -> Macro.escape(opts[:build])
        end

      if not is_nil(repo) and opts[:insert?] != false do
        # Handle `:after_insert` hook
        after_insert_handler =
          case opts[:after_insert] do
            nil -> &FactoryMan.after_insert_default_handler/1
            after_insert_handler -> after_insert_handler
          end

        # Insert
        insert_function_name = :"insert_#{factory_name}!"

        def unquote(insert_function_name)(params \\ %{}) do
          params
          |> unquote(build_function_name)()
          |> unquote(repo).insert!()
          |> then(unquote(after_insert_handler))
        end

        defoverridable [{build_function_name, 1}, {insert_function_name, 1}]
      else
        defoverridable [{build_function_name, 1}]
      end
    end
  end

  @doc """
  The default `:after_insert` handler. Returns the unmodified struct.

  ## Examples

      iex> FactoryMan.after_insert_default_handler(%SomeProject.Struct{id: 123})
      %SomeProject.Struct{id: 123}
  """
  def after_insert_default_handler(%_{} = inserted_struct), do: inserted_struct
end
