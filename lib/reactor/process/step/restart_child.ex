defmodule Reactor.Process.Step.RestartChild do
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
                  doc: "The PID or ID of the child to remove"
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
  Restarts a child process identified by child_id.

  See `Supervisor.restart_child/2` for more information.

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
      restart_child(arguments, options)
    end
  end

  defp restart_child(arguments, options) do
    case options[:module].restart_child(arguments[:supervisor], arguments[:child_id]) do
      {:error, reason} -> {:error, reason}
      _ -> {:ok, :ok}
    end
  end
end
