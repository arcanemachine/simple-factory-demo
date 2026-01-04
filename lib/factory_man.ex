defmodule FactoryMan do
  @moduledoc """
  Create and customize test factories for generating synthetic data during tests.

  ## Getting started

  ## Creating base factories

  Put the base factory in `test/support/factory.ex` (e.g. `YourProject.Factory`). This will be
  used to to build child factories. You should also define more base factories in this namespace
  if needed (e.g. `YourProject.Factory.OtherFactory`).

  > #### Tip {: .tip}
  >
  > Base factories SHOULD be located in a non-pluralized namespace (e.g. `YourProject.Factory`).

  ## Creating factory instances

  Create a factory instance for each context (e.g. A module called `YourProject.Factories.Users`
  in a file called `test/support/factories/users.ex`).

  Factory instances SHOULD be located in `test/support/factories/[your_context].ex`.

  > #### Tip {: .tip}
  >
  > Factory instances SHOULD be located in a pluralized namespace (e.g.
  > `YourProject.Factories.Users`).
  """

  defmacro __using__(opts \\ []) do
    quote do
      # Import factory macro
      import unquote(__MODULE__), only: [factory: 1]
      alias unquote(__MODULE__)

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

      # Put options into a module attribute that can be read by the factory instances
      Module.register_attribute(__MODULE__, :factory_opts, persist: true)
      Module.put_attribute(__MODULE__, :factory_opts, factory_opts)

      def __FACTORY__, do: @factory_opts
    end
  end

  defmacro factory(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      opts =
        Module.get_attribute(__MODULE__, :factory_opts)
        |> Keyword.delete(:extends)
        |> Keyword.merge(opts)

      repo = opts[:repo]

      factory_name = Keyword.fetch!(opts, :name)

      def unquote(String.to_atom("__#{String.upcase("#{factory_name}")}_FACTORY__"))(),
        do: unquote(opts)

      # Build
      {build_function_name, _build_function_arity} = Macro.escape(opts[:build])

      if not is_nil(repo) and opts[:insert!] != false do
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

  @doc "The default `:after_insert` handler. Returns the unmodified struct."
  def after_insert_default_handler(%_{} = inserted_struct), do: inserted_struct
end
