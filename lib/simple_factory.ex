defmodule SimpleFactory do
  @moduledoc """
  A simple factory product builder. Useful for generating dummy data.

  ## Getting started

  For testing, factories may be located in `test/support/factories/[your_context].ex`.
  """

  defmacro __using__(_opts) do
    quote do
      def hello, do: :world
    end
  end
end
