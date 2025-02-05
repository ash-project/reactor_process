defmodule Reactor.Process.SupervisorCountChildrenTest do
  @moduledoc false
  use ExUnit.Case, async: true

  defmodule CountChildrenReactor do
    @moduledoc false
    use Reactor, extensions: [Reactor.Process]

    input :supervisor

    count_children :count_children do
      supervisor input(:supervisor)
    end

    return :count_children
  end

  test "it returns the count of children" do
    {:ok, pid} = Supervisor.start_link([], strategy: :one_for_one)

    Supervisor.start_child(pid, {Support.StubServer, on_init: {:ok, nil}})

    assert {:ok, count} = Reactor.run(CountChildrenReactor, %{supervisor: pid})
    assert count.active == 1
    assert count.workers == 1
    assert count.supervisors == 0
    assert count.specs == 1
  end
end
