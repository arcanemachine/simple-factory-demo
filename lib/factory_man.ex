defmodule FactoryMan do
  @moduledoc """
  Create and customize test factories for synthetic data generation during tests.

  ## Getting started

  Factories may be located in `test/support/factories/[your_context].ex`.
  """

  defmacro __using__(opts \\ []) do
    {parent_repo, _opts} = Keyword.get(opts, :repo)

    quote do
      import FactoryMan

      defmacro __using__(opts \\ []) do
        {repo, opts} = Keyword.get(opts, :repo, unquote(parent_repo))

        quote do
          @factory_repo unquote(opts[:repo])

          defmacro factory(schema, opts \\ []) do
            quote bind_quoted: [schema: schema, opts: opts] do
              factory_name =
                Keyword.get(
                  opts,
                  :name,
                  schema |> Module.split() |> List.last() |> String.downcase()
                )

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
      end

      @spec insert!(module(), struct()) :: struct()
      def insert!(repo, struct), do: repo.insert(struct)

      defoverridable insert!: 2
    end
  end
end
