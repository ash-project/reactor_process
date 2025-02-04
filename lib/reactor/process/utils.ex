defmodule Reactor.Process.Utils do
  @moduledoc false

  alias Reactor.Process.Errors.TerminateTimeoutError

  @doc "Terminate a process while waiting for it to exit"
  def terminate(pid, reason, timeout, step) when is_pid(pid) do
    ref = Process.monitor(pid)
    Process.unlink(pid)
    Process.exit(pid, reason)

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
end
