defmodule FactoryMan do
  @moduledoc """
  Create and customize test factories for generating synthetic data during tests.

  ## Getting started

  ## Creating factory definitions

  Put factory definitions in `test/support/factory.ex` (e.g. `YourProject.Factory`). This will be
  used to to build factory instances. You should also define more factories in this namespace if
  needed (e.g. `YourProject.Factory.OtherFactory`).

  > #### Tip {: .tip}
  >
  > Factory definitions SHOULD be located in a non-pluralized namespace (e.g.
  > `YourProject.Factory`).

  ## Creating factory instances

  Create a factory instance for each context (e.g. `test/support/factories/users.ex`
  (`YourProject.Factories.Users`).

  Factory instances SHOULD be located in `test/support/factories/[your_context].ex`.

  > #### Tip {: .tip}
  >
  > Factory instances SHOULD be located in a pluralized namespace (e.g.
  > `YourProject.Factories.Users`).
  """

  defmacro __using__(definition_opts \\ []) do
    # {definition_repo, _opts} = Keyword.get(opts, :repo)

    quote do
      defmacro __using__(instance_opts \\ []) do
        # {repo, opts} = Keyword.get(opts, :repo, definition_opts[:repo])

        # definition_opts = unquote(Macro.escape(definition_opts))
        definition_opts = unquote(Macro.escape(definition_opts))

        quote do
          # @factory_repo unquote(opts[:repo])

          # merged_definition_instance_opts = Keyword.merge(unquote(definition_opts), unquote(instance_opts))

          # Keyword.merge(unquote(definition_opts), unquote(instance_opts))
          # |> IO.inspect(label: :fixme1)

          # opts = unquote(definition_opts) |> Keyword.merge(unquote(instance_opts))

          # def hello, do: unquote(definition_opts)
          merged_definition_instance_opts =
            Keyword.merge(unquote(definition_opts), unquote(instance_opts))

          def merged_definition_instance_opts,
            do: Keyword.merge(unquote(definition_opts), unquote(instance_opts))

          # defmacro factory(schema, factory_opts \\ []) do
          defmacro factory(factory_opts \\ []) do
            # merged_definition_instance_opts = unquote(Macro.escape(merged_definition_instance_opts))

            # definition_opts = unquote(Macro.escape(definition_opts))
            # instance_opts = unquote(Macro.escape(instance_opts))

            opts = factory_opts

            # opts =
            #   unquote(definition_opts)
            #   |> Keyword.merge(unquote(instance_opts))
            #   |> Keyword.merge(factory_opts)

            quote do
              # import __MODULE__

              def hello, do: unquote(opts)

              # opts = Keyword.merge(unquote(merged_definition_instance_opts), unquote(factory_opts))

              # factory_name =
              #   Keyword.get(
              #     factory_opts,
              #     :name,
              #     schema |> Module.split() |> List.last() |> String.downcase()
              #   )

              # # Build
              # build_function_name = :"build_#{factory_name}"

              # def unquote(build_function_name)(params \\ %{})

              # def unquote(build_function_name)(params) do
              #   struct(unquote(schema), params)
              # end

              # defoverridable [{build_function_name, 1}]

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
      end

      # @spec insert!(module(), struct()) :: struct()
      # def insert!(repo, struct), do: repo.insert(struct)

      # defoverridable insert!: 2
    end
  end
end
