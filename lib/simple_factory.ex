defmodule SimpleFactory do
  @moduledoc """
  This project generates test factories for automated testing.

  ## Getting started

  For testing, factories may be located in `test/support/factories/[your_context].ex`.
  """

  defmacro factory(schema, repo, opts \\ []) do
    quote bind_quoted: [schema: schema, repo: repo, opts: opts] do
      # {repo, opts} = Keyword.pop(opts, :repo)
      # {schema, opts} = Keyword.pop(opts, :schema)

      # factory_name = Keyword.get(opts, :name, schema |> Module.split() |> List.last())
      factory_name = schema |> Module.split() |> List.last() |> String.downcase()

      build_function_name = :"build_#{factory_name}"

      def unquote(build_function_name)(params \\ %{}) do
        struct(unquote(schema), params)
      end

      insert_function_name = :"insert_#{factory_name}"

      def unquote(insert_function_name)(params \\ %{}) do
        apply(__MODULE__, unquote(build_function_name), params) |> unquote(repo).insert()
      end
    end
  end
end
