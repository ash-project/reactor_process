defmodule Reactor.Process.Utils do
  @moduledoc false
  alias Reactor.Process.Errors.TerminateTimeoutError

  @doc "Terminate a process while waiting for it to exit"
  @spec terminate(pid, any, timeout, Reactor.Step.t()) ::
          :ok | {:error, TerminateTimeoutError.t()}
  def terminate(pid, reason, timeout, step) when is_pid(pid) do
    ref = Process.monitor(pid)
    Process.unlink(pid)
    Process.exit(pid, reason)

    await_exit(pid, ref, timeout, step)
  end

  @doc "Await a process termination"
  @spec await_exit(pid, reference, timeout, Reactor.Step.t()) ::
          :ok | {:error, TerminateTimeoutError.t()}
  def await_exit(pid, ref, timeout, step) do
    receive do
      {:DOWN, ^ref, :process, ^pid, _} ->
        Process.demonitor(ref, [:flush])
        :ok
    after
      timeout ->
        Process.demonitor(ref, [:flush])

        {:error,
         TerminateTimeoutError.exception(
           step: step,
           timeout: timeout,
           process: pid
         )}
    end
  end

  @doc "Convert a module spec into a child spec"
  @spec child_spec(Supervisor.module_spec()) :: {:ok, Supervisor.child_spec()} | {:error, any}
  def child_spec({module, opts}) do
    {:ok, module.child_spec(opts)}
  rescue
    error -> {:error, error}
  end

  def child_spec(module) do
    {:ok, module.child_spec([])}
  rescue
    error -> {:error, error}
  end
end
