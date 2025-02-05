defmodule Reactor.Process.Step.TerminateChild do
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
                ],
                fail_on_not_found?: [
                  type: :boolean,
                  required: false,
                  default: true,
                  doc:
                    "Whether the step should fail if the no child is found under the `child_id`"
                ],
                restart_on_undo?: [
                  type: :boolean,
                  required: false,
                  default: true,
                  doc:
                    "Whether to terminate the started process when the Reactor is undoing changes"
                ]
              )

  @moduledoc """
  Terminates the given child identified by `child_id`.

  See the documentation for `Supervisor.terminate_child/2` for more information.

  ## Restarting

  When the reactor is undoing changes, it is possible for this step to restart
  the terminated child using `restart_child/2`. Be aware that this will only
  work if the child spec hasn't subsequently been deleted by another step and
  the `restart_child/2` function is present on the module (ie not
  `DynamicSupervisor`).

  > #### Child ID {: .tip}
  >
  > The `child_id` argument can take either a traditional child ID (for a
  > traditional `Supervisor`) or a PID (for a `DynamicSupervisor`). It's up to
  > you to make sure you provide the correct inputs.

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
      terminate_child(arguments, options)
    end
  end

  @doc false
  @impl true
  def can?(%{impl: {_, options}}, :undo), do: Keyword.get(options, :restart_on_undo?, true)
  def can?(_, :undo), do: false
  def can?(step, capability), do: super(step, capability)

  @doc false
  @impl true
  def undo(_, arguments, _context, options) do
    with {:ok, options} <- Spark.Options.validate(options, @opt_schema) do
      if Keyword.get(options, :restart_on_undo?, false) do
        restart_child(arguments, options)
      else
        :ok
      end
    end
  end

  defp terminate_child(arguments, options) do
    fail_on_not_found? = options[:fail_on_not_found?]

    case options[:module].terminate_child(arguments[:supervisor], arguments[:child_id]) do
      {:error, :not_found} when fail_on_not_found? == true -> {:error, :not_found}
      {:error, :not_found} -> {:ok, :not_found}
      _ -> {:ok, :ok}
    end
  end

  defp restart_child(arguments, options) do
    case options[:module].restart_child(arguments[:supervisor], arguments[:child_id]) do
      {:error, reason} -> {:error, reason}
      _ -> :ok
    end
  end
end
