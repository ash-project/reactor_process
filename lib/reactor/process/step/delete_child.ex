defmodule Reactor.Process.Step.DeleteChild do
  @arg_schema Spark.Options.new!(
                supervisor: [
                  type:
                    {:or,
                     [
                       :pid,
                       :atom,
                       {:tuple, [{:literal, :global}, :any]},
                       {:tuple, [{:literal, :via}, :module, :any]},
                       {:tuple, [:atom, :atom]}
                     ]},
                  required: true,
                  doc: "The supervisor to query"
                ],
                child_id: [
                  type: :any,
                  required: true,
                  doc: "The ID of the child to remove"
                ]
              )

  @opt_schema Spark.Options.new!(
                module: [
                  type: :module,
                  required: false,
                  default: Supervisor,
                  doc: "The module to use. Must export `count_children/1`"
                ]
              )

  @moduledoc """
  Deletes a child specification by id from a Supervisor.

  See the documentation for `Supervisor.delete_child/2` for more information.

  ## Arguments

  #{Spark.Options.docs(@arg_schema)}

  ## Options

  #{Spark.Options.docs(@opt_schema)}
  """
  use Reactor.Step

  @doc false
  @impl true
  def run(arguments, _context, options) do
    with {:ok, arguments} <- Spark.Options.validate(Enum.to_list(arguments), @arg_schema),
         {:ok, options} <- Spark.Options.validate(options, @opt_schema),
         :ok <- options[:module].delete_child(arguments[:supervisor], arguments[:child_id]) do
      {:ok, :ok}
    end
  end
end
