defmodule FactoryMan do
  @moduledoc """
  Create and customize test factories for generating synthetic data during tests.

  ## Getting started

  ## Creating factory parents

  Put factory parents in `test/support/factory.ex` (e.g. `YourProject.Factory`). This will be
  used to to build factory instances. You should also define more factories in this namespace if
  needed (e.g. `YourProject.Factory.OtherFactory`).

  > #### Tip {: .tip}
  >
  > Factory parents SHOULD be located in a non-pluralized namespace (e.g.
  > `YourProject.Factory`).

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
      # Import factory macro from current module
      import unquote(__MODULE__)

      @before_compile unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :factory_opts, persist: true)

      # Put options into a temporary module attribute that can be read in `__before_compile__/1`
      Module.put_attribute(__MODULE__, :opts, unquote(opts))
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      {extends, opts} = Keyword.pop(@opts, :extends)

      factory_opts =
        case extends do
          nil ->
            # Use opts from current factory only
            @opts

          extends ->
            # Extend parent factory opts
            parent_opts = extends.__info__(:attributes)[:factory_opts] || []

            Keyword.merge(parent_opts, @opts)
        end

      Module.put_attribute(__MODULE__, :factory_opts, factory_opts)

      # Delete temporary module attribute `:opts`
      Module.delete_attribute(__MODULE__, :opts)

      # Temp debug stuff
      def _get_opts, do: @factory_opts
    end
  end

  defmacro factory(schema, opts \\ []) do
    quote bind_quoted: [schema: schema, opts: opts] do
      {repo, opts} = Keyword.pop(opts, :repo, @factory_opts[:repo])

      {factory_name, opts} =
        Keyword.pop(opts, :repo, schema |> Module.split() |> List.last() |> String.downcase())

      # unquote(opts)[:build]
      # Macro.escape(opts[:build] |> IO.inspect(label: :fixme1))

      # Build
      if opts[:build] != nil do
        Macro.escape(opts[:build])
      else
        build_function_name = :"build_#{factory_name}"

        def unquote(build_function_name)(params \\ %{}) do
          struct(unquote(schema), params)
        end

        # defoverridable [{build_function_name, 1}]
      end

      # # Insert!
      # if not is_nil(repo) do
      #   insert_function_name = :"insert_#{factory_name}!"

      #   def unquote(insert_function_name)(params \\ %{})

      #   def unquote(insert_function_name)(params) do
      #     built_item = unquote(build_function_name)(params)

      #     FactoryMan.insert(unquote(repo), built_item)
      #   end

      #   defoverridable [{build_function_name, 1}, {insert_function_name, 1}]
      # end
    end
  end
end
