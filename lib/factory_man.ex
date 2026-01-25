defmodule FactoryMan do
  @moduledoc """
  Create and customize test factories for generating synthetic data during tests.

  ## Getting started

  - Install the application:

  `your_project/mix.exs`
  ```elixir
  FIXME
  ```

  > FIXME: Add instructions for adding it to test/non-test environments

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
  %YourProject.Users.Profile{id: 1, user: %YourProject.Users.User{id: 2, username: "user-12345"}}

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

  #### `:extends` (module) - Reduce boilerplate by inheriting options from a parent factory

  You may create a "base" factory, which can be extended to produce "child" factories (which
  inherit the options set in the parent factory module(s)):

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

  This child factory will now use any options set in the parent factory (repo, hooks, etc.).

  ## Factory conventions

  > NOTE: These conventions are guidelines, not rules.

  - You should define base factories in the singular namespace (e.g. `YourProject.Factory`), and
  child factories in the plural namespace (e.g. `YourProject.Factories.Users`).
    - For more info on "base" and "child" factories, see the section `:extends` option.

  - If you are not using "base" and "child" factories, then you should only use the plural
  namespace for your factories (e.g. `YourProject.Factories.Users`).

  - Create a separate factory for each context. Your factory module hierarchy should match your
  context module hierarchy. For example, if you have a context `YourProject.Users`, you should
  have a factory called `YourProject.Factories.Users`.

  ## Debugging

  A debug helper function is generated for each factory (both for the factory module, and for each
  factory macro) which shows all options that have been passed into the factory item. This
  function may be useful during debugging. For example:

  `your_project/test/support/factory.ex`
  ```
  defmodule YourProject.Factory do
    use FactoryMan, repo: YourProject.Repo

    factory(name: :something, build: def(build_something(_ \\ 0), do: :something), insert?: false)
  end
  ```

  The module above will generate the functions `YourProject.Factory._factory_opts/0` and
  `YourProject.Factory._something_opts/0`, which can be called in IEx to view all options that
  have been used to build those factory items:

  ```elixir
  iex> YourProject.Factory._factory_opts()
  [repo: YourProject.Repo]

  iex> YourProject.Factory._something_factory_opts()
  [repo: YourProject.Repo, name: :something, build: {:build_something, 1}, insert?: false]
  ```

  ## Common recipes

  FIXME: Add common recipes here (e.g. Add assocs, assoc attrs, etc.)
  """

  defmacro __using__(opts \\ []) do
    quote do
      # Import factory macro
      import unquote(__MODULE__), only: [factory: 2]

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

      # Put factory module options into a module attribute that can be read by the child factories
      Module.register_attribute(__MODULE__, :factory_opts, persist: true)
      Module.put_attribute(__MODULE__, :factory_opts, factory_opts)

      # @doc "A debug helper function that can show all the options used in this factory module."
      # def _factory_opts, do: @factory_opts
    end
  end

  # defmacro factory(factory_name, params \\ %{}, opts) do
  #   {do_block, _opts} = Keyword.pop(opts, :do)

  #   # quote do
  #   #   factory(factory_name, build: unquote(do_block))
  #   # end

  #   build_function_name = :"build_#{factory_name}"

  #   quote do
  #

  #     def unquote(build_function_name)(var!(params) \\ unquote(params)) do
  #       unquote(do_block)
  #     end
  #   end
  # end

  defmacro factory(factory_name, opts) do
    quote do
      opts = unquote(opts)

      factory_opts = Module.get_attribute(__MODULE__, :factory_opts)

      opts =
        factory_opts
        # Drop keys that do not pertain to individual factories
        |> Keyword.drop([:extends])
        |> Keyword.merge(opts)

      # @doc "A debug helper function that shows all the options used in this factory."
      # def unquote(String.to_atom("_#{factory_name}_factory_opts"))(),
      #   do: unquote(Keyword.merge(factory_opts, opts))

      hooks = opts[:hooks] || []
      repo = opts[:repo]

      # Build function
      public_build_function_name = :"build_#{factory_name}"

      public_build_function_ast =
        {:def, meta, [{public_build_function_name, context, args}, [do: body]]} =
        unquote(opts[:do])

      private_build_function_name = :"_#{public_build_function_name}_without_hooks"

      private_build_function_ast =
        {:def, meta, [{private_build_function_name, context, args}, [do: body]]}

      # Generate private build function (no hooks)
      Code.eval_quoted(private_build_function_ast, [], __ENV__)

      # Generate public build function (with hooks)
      def unquote(public_build_function_name)(params \\ %{}) do
        params
        |> then(&FactoryMan.get_hook_handler(unquote(hooks), :before_build).(&1))
        |> unquote(private_build_function_name)()
        |> then(&FactoryMan.get_hook_handler(unquote(hooks), :after_build).(&1))
      end

      if not is_nil(repo) and opts[:insert?] != false do
        # Insert function
        insert_function_name = :"insert_#{factory_name}!"

        def unquote(insert_function_name)(params \\ %{}) do
          params
          |> unquote(public_build_function_name)()
          |> then(&FactoryMan.get_hook_handler(unquote(hooks), :before_insert).(&1))
          |> unquote(repo).insert!()
          |> then(&FactoryMan.get_hook_handler(unquote(hooks), :after_insert).(&1))
        end
      end
    end
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
end
