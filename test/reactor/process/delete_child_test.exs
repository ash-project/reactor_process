defmodule Reactor.Process.DeleteChildTest do
  @moduledoc false
  use ExUnit.Case, async: true

  defmodule DeleteChildReactor do
    @moduledoc false
    use Reactor, extensions: [Reactor.Process]

    input :supervisor
    input :child_id

    delete_child :delete_child do
      supervisor input(:supervisor)
      child_id(input(:child_id))
    end

    return :delete_child
  end

  test "it removes a child from the supervisor" do
    {:ok, pid} = Supervisor.start_link([], strategy: :one_for_one)

    {:ok, _} = Supervisor.start_child(pid, {Support.StubServer, on_init: {:ok, nil}})
    :ok = Supervisor.terminate_child(pid, Support.StubServer)
    %{specs: 1} = Supervisor.count_children(pid)

    assert :ok =
             Reactor.run!(DeleteChildReactor, %{supervisor: pid, child_id: Support.StubServer})

    assert %{specs: 0} = Supervisor.count_children(pid)
  end
end
