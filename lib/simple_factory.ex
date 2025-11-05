defmodule SimpleFactory do
  @moduledoc """
  This project generates test factories for automated testing.

  ## Getting started

  For testing, factories may be located in `test/support/factories/[your_context].ex`.
  """

  defmacro __using__(opts \\ []) do
    quote do
      @repo unquote(opts[:repo])
    end
  end

  defmacro factory(schema, opts \\ []) do
    quote bind_quoted: [schema: schema, opts: opts] do
      {repo, opts} = Keyword.pop(opts, :repo, @factory_repo || raise("repo not declared"))

      factory_name =
        Keyword.get(opts, :name, schema |> Module.split() |> List.last() |> String.downcase())

      # Build action
      build_function_name = :"build_#{factory_name}"

      def unquote(build_function_name)(params \\ %{}) do
        struct(unquote(schema), params)
      end

      # Custom actions
      def unquote(:"insert_#{factory_name}")(params \\ %{}) do
        apply(__MODULE__, unquote(build_function_name), params) |> unquote(repo).insert()
      end
    end
  end
end
