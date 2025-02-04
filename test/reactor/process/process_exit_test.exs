defmodule Reactor.Process.ProcessExitTest do
  @moduledoc false
  use ExUnit.Case, async: true

  defmodule WaitForProcessExitReactor do
    @moduledoc false
    use Reactor, extensions: [Reactor.Process]

    input :pid
    input :reason
    input :timeout

    process_exit :exit do
      process input(:pid)
      reason input(:reason)
      timeout input(:timeout)
      wait_for_exit? true
    end
  end

  test "when the process doesn't exit it times out" do
    pid = start_link_supervised!({Support.StubServer, on_init: {:ok, nil}})

    assert {:error, timeout} =
             Reactor.run(WaitForProcessExitReactor, %{pid: pid, reason: :normal, timeout: 100})

    assert Process.alive?(pid)
    assert Exception.message(timeout) =~ ~r/timeout/
  end

  test "it terminates the process" do
    pid = start_supervised!({Support.StubServer, on_init: {:ok, nil}})

    Reactor.run!(WaitForProcessExitReactor, %{pid: pid, reason: :kill, timeout: 100})

    refute Process.alive?(pid)
  end
end
