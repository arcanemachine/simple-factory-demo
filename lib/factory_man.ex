defmodule FactoryMan do
  @moduledoc """
  Create and customize test factories for generating synthetic data during tests.

  ## Getting started

  ## Creating base factories

  Put base factory in `test/support/factory.ex` (e.g. `YourProject.Factory`). This will be
  used to to build child factory. You should also define more bases factories in this namespace if
  needed (e.g. `YourProject.Factory.OtherFactory`).

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
      import unquote(__MODULE__)

      factory_opts =
        case unquote(opts)[:extends] do
          nil ->
            # Use opts from current factory only
            unquote(opts)

          extends ->
            # Extend parent factory opts
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

      if not is_nil(repo) do
        # After insert
        after_insert_function_name = :"after_insert_#{factory_name}"

        def unquote(after_insert_function_name)(struct) do
          # Reset all assoc fields so that the struct matches a DB query result
          Ecto.reset_fields(struct, struct.__struct__.__schema__(:associations))
        end

        # Insert!
        insert_function_name = :"insert_#{factory_name}!"

        def unquote(insert_function_name)(params \\ %{}) do
          params
          |> unquote(build_function_name)()
          |> unquote(repo).insert!()
          |> unquote(after_insert_function_name)()
        end

        defoverridable [
          {build_function_name, 1},
          {insert_function_name, 1}
          # {insert_function_name, 1},
          # {after_insert_function_name, 1}
        ]
      else
        defoverridable [{build_function_name, 1}]
      end
    end
  end
end
