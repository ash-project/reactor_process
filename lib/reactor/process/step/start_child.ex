# SPDX-FileCopyrightText: 2025 reactor_process contributors <https://github.com/ash-project/reactor_process/graphs/contributors>
#
# SPDX-License-Identifier: MIT

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

  ## Result

  The step returns a `Reactor.Process.Step.StartChild.Result`. The `pid` field
  is the child process. The `id` field is the id from the child spec. The
  `started?` field records whether this step started the child.

  When `fail_on_already_started?` is `false` and the child is already started,
  the step returns that child with `started?: false`.

  When `fail_on_already_present?` is `false` and the child spec is present but
  the child is stopped, the step restarts the child with `restart_child/2` and
  returns it with `started?: true`. If the supervisor module does not export
  `restart_child/2`, the step fails with `{:error, :already_present}`.

  ## Undo

  Undo only acts on a child that this step started. Undo does not touch a
  child with `started?: false`.

  When `terminate_on_undo?` is `true`, undo terminates the child with
  `terminate_child/2`, waits for it to exit, and then removes the child spec
  with `delete_child/2`. This returns the supervisor to the state it had before
  the step ran. If the supervisor module does not export `delete_child/2`, the
  child spec stays in the supervisor.

  ## Arguments

  #{Spark.Options.docs(@arg_schema)}

  ## Options

  #{Spark.Options.docs(@opt_schema)}
  """
  use Reactor.Step
  import Reactor.Process.Utils

  defmodule Result do
    @moduledoc """
    The result of a `start_child` step.
    """
    defstruct [:pid, :id, started?: false]

    @type t :: %__MODULE__{
            pid: pid,
            id: term,
            started?: boolean
          }
  end

  @doc false
  @impl true
  def run(arguments, _context, options) do
    with {:ok, arguments} <- Spark.Options.validate(Enum.to_list(arguments), @arg_schema),
         {:ok, options} <- Spark.Options.validate(options, @opt_schema),
         {:ok, %{id: id}} <- child_spec(arguments[:child_spec]) do
      start_child(arguments, options, id)
    end
  end

  @doc false
  @impl true
  def can?(%{impl: {_, options}}, :undo), do: Keyword.get(options, :terminate_on_undo?, true)
  def can?(_, :undo), do: true
  def can?(step, capability), do: super(step, capability)

  @doc false
  @impl true
  def undo(%Result{started?: false}, _arguments, _context, _options), do: :ok

  def undo(%Result{pid: pid, id: id}, arguments, context, options) do
    with {:ok, arguments} <- Spark.Options.validate(Enum.to_list(arguments), @arg_schema),
         {:ok, options} <- Spark.Options.validate(options, @opt_schema) do
      ref = Process.monitor(pid)
      options[:module].terminate_child(arguments[:supervisor], id)

      with :ok <- await_exit(pid, ref, options[:termination_timeout], context.current_step) do
        delete_child(options[:module], arguments[:supervisor], id)
      end
    end
  end

  defp start_child(arguments, options, id) do
    fail_on_already_started? = options[:fail_on_already_started?]
    fail_on_already_present? = options[:fail_on_already_present?]

    case options[:module].start_child(arguments[:supervisor], arguments[:child_spec]) do
      {:ok, pid} ->
        {:ok, %Result{pid: pid, id: id, started?: true}}

      {:ok, pid, _} ->
        {:ok, %Result{pid: pid, id: id, started?: true}}

      {:error, {:already_started, pid}} when fail_on_already_started? == true ->
        {:error, {:already_started, pid}}

      {:error, {:already_started, pid}} ->
        {:ok, %Result{pid: pid, id: id, started?: false}}

      {:error, :already_present} when fail_on_already_present? == true ->
        {:error, :already_present}

      {:error, :already_present} ->
        restart_child(arguments, options, id)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp restart_child(arguments, options, id) do
    module = options[:module]

    if function_exported?(module, :restart_child, 2) do
      case module.restart_child(arguments[:supervisor], id) do
        {:ok, pid} -> {:ok, %Result{pid: pid, id: id, started?: true}}
        {:ok, pid, _} -> {:ok, %Result{pid: pid, id: id, started?: true}}
        {:error, reason} -> {:error, reason}
      end
    else
      {:error, :already_present}
    end
  end

  defp delete_child(module, supervisor, id) do
    if function_exported?(module, :delete_child, 2) do
      case module.delete_child(supervisor, id) do
        :ok -> :ok
        {:error, :not_found} -> :ok
        {:error, reason} -> {:error, reason}
      end
    else
      :ok
    end
  end
end
