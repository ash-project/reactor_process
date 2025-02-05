defmodule Reactor.Process.RestartChildTest do
  @moduledoc false
  use ExUnit.Case, async: true

  defmodule RestartChildReactor do
    @moduledoc false
    use Reactor, extensions: [Reactor.Process]

    input :supervisor
    input :child_id

    restart_child :restart_child do
      supervisor input(:supervisor)
      child_id input(:child_id)
    end
  end

  test "when the child spec is present, it restarts the child" do
    {:ok, pid} = Supervisor.start_link([], strategy: :one_for_one)
    {:ok, _} = Supervisor.start_child(pid, {Support.StubServer, on_init: {:ok, nil}})
    :ok = Supervisor.terminate_child(pid, Support.StubServer)
    assert %{active: 0, specs: 1} = Supervisor.count_children(pid)

    assert :ok =
             Reactor.run!(RestartChildReactor, %{supervisor: pid, child_id: Support.StubServer})

    assert %{active: 1, specs: 1} = Supervisor.count_children(pid)
  end
end
