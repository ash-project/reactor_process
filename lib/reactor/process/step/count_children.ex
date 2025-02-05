defmodule Reactor.Process.Step.CountChildren do
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
  Returns information about a Supervisor's children.

  See the documentation for `Supervisor.count_children/1` for more information.

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
         {:ok, options} <- Spark.Options.validate(options, @opt_schema) do
      {:ok, options[:module].count_children(arguments[:supervisor])}
    end
  end
end
