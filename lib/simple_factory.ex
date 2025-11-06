defmodule SimpleFactory do
  @moduledoc """
  This project allows you to create test factories, eliminating boilerplate and accelerating
  testing workflows.

  ## Getting started

  For testing, factories may be located in `test/support/factories/[your_context].ex`.
  """

  defmacro __using__(opts \\ []) do
    quote do
      import SimpleFactory

      @factory_repo unquote(opts[:repo])
    end
  end

  defmacro factory(schema, opts \\ []) do
    quote bind_quoted: [schema: schema, opts: opts] do
      {repo, opts} = Keyword.pop(opts, :repo, @factory_repo)

      factory_name =
        Keyword.get(opts, :name, schema |> Module.split() |> List.last() |> String.downcase())

      # Build action
      build_function_name = :"build_#{factory_name}"

      def unquote(build_function_name)(params \\ %{}) do
        struct(unquote(schema), params)
      end

      # Custom actions
      if not is_nil(repo) do
        def unquote(:"insert_#{factory_name}")(params \\ %{}) do
          built_item = apply(__MODULE__, unquote(build_function_name), [params])

          unquote(repo).insert(built_item)
        end
      end
    end
  end
end
