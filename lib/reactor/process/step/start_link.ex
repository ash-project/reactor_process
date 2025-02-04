defmodule Reactor.Process.Step.StartLink do
  @arg_schema Spark.Options.new!(
                child_spec: [
                  type: {:or, [{:tuple, [:module, :keyword_list]}, :module]},
                  required: true,
                  doc: "The child spec"
                ]
              )
  @opt_schema Spark.Options.new!(
                fail_on_already_started?: [
                  type: :boolean,
                  required: false,
                  default: true,
                  doc:
                    "Whether the step should fail if the start function returns an already started error"
                ],
                fail_on_ignore?: [
                  type: :boolean,
                  required: false,
                  default: true,
                  doc: "Whether the step should fail if the start function returns `:ignore`"
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
  A Reactor step which starts a process via it's child spec and links it to the
  process which is running the Reactor.

  > #### Warning {: .warning}
  > If you are building your Reactor directly (rather than via the DSL) then
  > this step must be added with the `async?: false` option otherwise the step
  > will fail.

  The `child_spec` argument expects a `t:Supervisor.module_spec()`. The step
  will then use the `start` MFA returned by the module's `child_spec/1` function
  to start the child process.

  ## Arguments

  #{Spark.Options.docs(@arg_schema)}

  ## Options

  #{Spark.Options.docs(@opt_schema)}
  """
  use Reactor.Step
  alias Reactor.Process.Errors.{MissingMiddlewareError, TerminateTimeoutError}

  @doc false
  @impl true
  def run(arguments, %{Reactor.Process.Middleware => %{pid: pid}} = _context, options)
      when pid == self() do
    with {:ok, arguments} <- Spark.Options.validate(Enum.to_list(arguments), @arg_schema),
         {:ok, options} <- Spark.Options.validate(options, @opt_schema),
         {:ok, child_spec} <- child_spec(arguments[:child_spec]) do
      start_child(child_spec, options)
    end
  end

  def run(_arguments, context, _options) do
    {:error,
     MissingMiddlewareError.exception(
       step: context.current_step,
       message: """
       This step is not running in the same process as the Reactor, which means it has been run without the `async?: false` option.
       """
     )}
  end

  @doc false
  @impl true
  def can?(%{impl: {_, options}}, :undo), do: Keyword.get(options, :terminate_on_undo?, true)
  def can?(_, :undo), do: false
  def can?(step, capability), do: super(step, capability)

  @doc false
  @impl true
  def undo(process, _, context, options) do
    with {:ok, options} <- Spark.Options.validate(options, @opt_schema) do
      if Keyword.get(options, :terminate_on_undo?, true) do
        terminate(process, options, context)
      end

      :ok
    end
  end

  defp start_child(%{start: {module, function, args}}, options) do
    fail_on_already_started? = options[:fail_on_already_started?]
    fail_on_ignore? = options[:fail_on_ignore?]

    case apply(module, function, args) do
      {:ok, pid} ->
        Process.link(pid)
        {:ok, pid}

      :ignore when fail_on_ignore? == true ->
        {:error, "Child process returned `:ignore`"}

      :ignore ->
        {:ok, :ignore}

      {:error, {:already_started, pid}} when fail_on_already_started? == true ->
        {:error, {:already_started, pid}}

      {:error, {:already_started, pid}} ->
        Process.link(pid)
        {:ok, pid}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp start_child(_, _), do: {:error, "Invalid child spec"}

  defp child_spec({module, opts}) do
    {:ok, module.child_spec(opts)}
  rescue
    error -> {:error, error}
  end

  defp child_spec(module) do
    {:ok, module.child_spec([])}
  rescue
    error -> {:error, error}
  end

  defp terminate(process, options, context) do
    ref = Process.monitor(process)
    Process.unlink(process)
    Process.exit(process, options[:termination_reason])

    timeout = options[:termination_timeout]

    receive do
      {:DOWN, ^ref, :process, _, _} ->
        Process.demonitor(ref, [:flush])
        :ok
    after
      timeout ->
        Process.demonitor(ref, [:flush])

        {:error,
         TerminateTimeoutError.exception(
           step: context.current_step,
           timeout: timeout,
           process: process
         )}
    end
  end
end
