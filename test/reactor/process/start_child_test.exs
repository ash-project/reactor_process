defmodule Reactor.Process.StartChildTest do
  @moduledoc false
  use ExUnit.Case, async: true

  defmodule StartChildReactor do
    @moduledoc false
    use Reactor, extensions: [Reactor.Process]

    input :fail?
    input :supervisor
    input :child_spec

    start_child :start_child do
      supervisor input(:supervisor)
      child_spec(input(:child_spec))
      terminate_on_undo? true
    end

    flunk :fail, "abort" do
      wait_for :start_child
      argument :fail?, input(:fail?)

      where & &1.arguments.fail?
    end

    return :start_child
  end

  test "it adds the child to the supervisor" do
    {:ok, pid} =
      Supervisor.start_link([], strategy: :one_for_one)

    assert {:ok, child} =
             Reactor.run(StartChildReactor, %{
               supervisor: pid,
               child_spec: {Support.StubServer, on_init: {:ok, nil}},
               fail?: false
             })

    assert is_pid(child)

    assert %{specs: 1, active: 1} = Supervisor.count_children(pid)
  end

  test "it can terminate the child from the supervisor on reactor failure" do
    {:ok, pid} =
      Supervisor.start_link([], strategy: :one_for_one)

    assert {:error, error} =
             Reactor.run(StartChildReactor, %{
               supervisor: pid,
               child_spec: {Support.StubServer, on_init: {:ok, nil}},
               fail?: true
             })

    assert Exception.message(error) =~ ~r/abort/
    assert %{specs: 1, active: 0} = Supervisor.count_children(pid)
  end
end
