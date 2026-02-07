defmodule FactoryMan.Sequence do
  @moduledoc """
  Module for generating sequential values.

  Use `FactoryMan.sequence/1` or `FactoryMan.sequence/2` to generate
  sequential values instead of calling this module directly.

  ## Attribution

  This module is adapted from the sequence functionality in [ExMachina](https://github.com/thoughtbot/ex_machina),
  originally created by Thoughtbot. The implementation has been copied and modified to work with FactoryMan.
  We gratefully acknowledge the ExMachina team for this excellent approach to sequence generation.
  """

  use Agent

  @doc false
  def start_link(_) do
    Agent.start_link(fn -> Map.new() end, name: __MODULE__)
  end

  @doc """
  Reset all sequences so that the next sequence starts from 0

  ## Example

      FactoryMan.Sequence.next("joe") # "joe0"
      FactoryMan.Sequence.next("joe") # "joe1"

      FactoryMan.Sequence.reset()

      FactoryMan.Sequence.next("joe") # resets so the return value is "joe0"

  You can use list as well

      FactoryMan.Sequence.next("alphabet_sequence", ["A", "B"]) # "A"
      FactoryMan.Sequence.next("alphabet_sequence", ["A", "B"]) # "B"

      FactoryMan.Sequence.reset()

      FactoryMan.Sequence.next("alphabet_sequence", ["A", "B"]) # resets so the return value is "A"

  If you want to reset sequences at the beginning of every test, put it in a
  `setup` block in your test.

      setup do
        FactoryMan.Sequence.reset()
      end
  """

  @spec reset() :: :ok
  def reset do
    Agent.update(__MODULE__, fn _ -> Map.new() end)
  end

  @doc """
  Reset specific sequences so long as they already exist. The sequences
  specified will be reset to 0, while others will remain at their current index.

  You can reset a single sequence,

  ## Example

      FactoryMan.Sequence.next(:alphabet, ["A", "B", "C"]) # "A"
      FactoryMan.Sequence.next(:alphabet, ["A", "B", "C"]) # "B"

      FactoryMan.Sequence.reset(:alphabet)

      FactoryMan.Sequence.next(:alphabet, ["A", "B", "C"]) # "A"

  And you can also reset multiple sequences at once,

  ## Example

      FactoryMan.Sequence.next(:numeric, [1, 2, 3]) # 1
      FactoryMan.Sequence.next(:numeric, [1, 2, 3]) # 2
      FactoryMan.Sequence.next("joe") # "joe0"
      FactoryMan.Sequence.next("joe") # "joe1"

      FactoryMan.Sequence.reset(["joe", :numeric])

      FactoryMan.Sequence.next(:numeric, [1, 2, 3]) # 1
      FactoryMan.Sequence.next("joe") # "joe0"
  """

  @spec reset(any()) :: :ok
  def reset(sequence_names) when is_list(sequence_names) do
    Agent.update(__MODULE__, fn sequences ->
      Enum.reduce(sequence_names, sequences, &Map.put(&2, &1, 0))
    end)
  end

  def reset(sequence_name) do
    Agent.update(__MODULE__, fn sequences ->
      Map.put(sequences, sequence_name, 0)
    end)
  end

  @doc false
  def next(sequence_name) when is_binary(sequence_name) do
    next(sequence_name, &(sequence_name <> to_string(&1)))
  end

  @doc false
  def next(sequence_name) do
    raise(
      ArgumentError,
      "Sequence name must be a string, got #{inspect(sequence_name)} instead"
    )
  end

  @doc false
  def next(sequence_name, [_ | _] = list) do
    length = length(list)

    Agent.get_and_update(__MODULE__, fn sequences ->
      current_value = Map.get(sequences, sequence_name, 0)
      index = rem(current_value, length)
      new_sequences = Map.put(sequences, sequence_name, index + 1)
      {value, _} = List.pop_at(list, index)
      {value, new_sequences}
    end)
  end

  @doc false
  def next(sequence_name, formatter, opts \\ []) do
    start_at = Keyword.get(opts, :start_at, 0)

    Agent.get_and_update(__MODULE__, fn sequences ->
      current_value = Map.get(sequences, sequence_name, start_at)
      new_sequences = Map.put(sequences, sequence_name, current_value + 1)
      {formatter.(current_value), new_sequences}
    end)
  end
end
