defmodule FactoryMan.Factories do
  @moduledoc "Define your factories."

  defmacro __using__(opts \\ []) do
    quote do
      @factory_repo unquote(opts[:repo])

      @spec insert!(module(), struct()) :: struct()
      def insert!(repo, struct), do: repo.insert(struct)

      defoverridable insert!: 2
    end
  end

  defmacro factory(schema, opts \\ []) do
    quote bind_quoted: [schema: schema, opts: opts] do
      {repo, opts} = Keyword.pop(opts, :repo, @factory_repo)

      factory_name =
        Keyword.get(opts, :name, schema |> Module.split() |> List.last() |> String.downcase())

      # Build
      build_function_name = :"build_#{factory_name}"

      def unquote(build_function_name)(params \\ %{})

      def unquote(build_function_name)(params) do
        struct(unquote(schema), params)
      end

      # Insert!
      insert_function_name = :"insert_#{factory_name}!"

      if not is_nil(repo) do
        def unquote(insert_function_name)(params \\ %{})

        def unquote(insert_function_name)(params) do
          built_item = apply(__MODULE__, unquote(build_function_name), [params])

          FactoryMan.insert(unquote(repo), built_item)
        end
      end

      defoverridable [{build_function_name, 1}, {insert_function_name, 1}]
    end
  end
end
