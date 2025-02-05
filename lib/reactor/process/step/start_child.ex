defmodule Reactor.Process.Step.StartChild do
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
                child_spec: [
                  type: {:or, [{:tuple, [:module, :keyword_list]}, :module]},
                  required: true,
                  doc: "The child spec"
                ]
              )

  @opt_schema Spark.Options.new!(
                module: [
                  type: :module,
                  required: false,
                  default: Supervisor,
                  doc: "The module to use. Must export `count_children/1`"
                ],
                fail_on_already_present?: [
                  type: :boolean,
                  required: false,
                  default: true,
                  doc:
                    "Whether the step should fail if the child spec is already present in the supervisor"
                ],
                fail_on_already_started?: [
                  type: :boolean,
                  required: false,
                  default: true,
                  doc:
                    "Whether the step should fail if the start function returns an already started error"
                ],
                terminate_on_undo?: [
                  type: :boolean,
                  required: false,
                  default: true,
                  doc:
                    "Whether to terminate the started process when the Reactor is undoing changes"
                ],
                termination_reason: [
                  type: :any,
                  required: false,
                  default: :kill,
                  doc: "The reason to give to the process when terminating it"
                ],
                termination_timeout: [
                  type: :timeout,
                  required: false,
                  default: 5_000,
                  doc: "How long to wait for a process to terminate"
                ]
              )

  @moduledoc """
  Adds a child specification to a supervisor and starts that child.

  See the documentation for `Supervisor.start_child/2` for more information.

  ## Arguments

  #{Spark.Options.docs(@arg_schema)}

  ## Options

  #{Spark.Options.docs(@opt_schema)}
  """
  use Reactor.Step
  import Reactor.Process.Utils

  @doc false
  @impl true
  def run(arguments, _context, options) do
    with {:ok, arguments} <- Spark.Options.validate(Enum.to_list(arguments), @arg_schema),
         {:ok, options} <- Spark.Options.validate(options, @opt_schema) do
      start_child(arguments, options)
    end
  end

  @doc false
  @impl true
  def can?(%{impl: {_, options}}, :undo), do: Keyword.get(options, :terminate_on_undo?, false)
  def can?(_, :undo), do: false
  def can?(step, capability), do: super(step, capability)

  @doc false
  @impl true
  def undo(pid, arguments, context, options) do
    with {:ok, arguments} <- Spark.Options.validate(Enum.to_list(arguments), @arg_schema),
         {:ok, options} <- Spark.Options.validate(options, @opt_schema) do
      if Keyword.get(options, :terminate_on_undo?, true) do
        with {:ok, %{id: id}} <- child_spec(arguments[:child_spec]) do
          ref = Process.monitor(pid)
          options[:module].terminate_child(arguments[:supervisor], id)
          await_exit(pid, ref, options[:termination_timeout], context.current_step)
        end
      else
        :ok
      end
    end
  end

  defp start_child(arguments, options) do
    fail_on_already_started? = options[:fail_on_already_started?]
    fail_on_already_present? = options[:fail_on_already_present?]

    case options[:module].start_child(arguments[:supervisor], arguments[:child_spec]) do
      {:ok, child} ->
        {:ok, child}

      {:ok, child, _} ->
        {:ok, child}

      {:error, {:already_started, child}} when fail_on_already_started? == true ->
        {:error, {:already_started, child}}

      {:error, {:already_started, child}} ->
        {:ok, child}

      {:error, :already_present} when fail_on_already_present? == true ->
        {:error, :already_present}

      {:error, :already_present} ->
        {:ok, :already_present}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
