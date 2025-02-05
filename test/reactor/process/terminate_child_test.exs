defmodule Reactor.Process.TerminateChildTest do
  @moduledoc false
  use ExUnit.Case, async: true

  defmodule TerminateChildReactor do
    @moduledoc false
    use Reactor, extensions: [Reactor.Process]

    input :fail?
    input :supervisor
    input :child_id

    terminate_child :terminate_child do
      supervisor input(:supervisor)
      child_id(input(:child_id))
      restart_on_undo?(true)
    end

    flunk :fail, "abort" do
      wait_for :terminate_child
      argument :fail?, input(:fail?)

      where & &1.arguments.fail?
    end

    return :terminate_child
  end

  test "it stops the child" do
    {:ok, pid} = Supervisor.start_link([], strategy: :one_for_one)
    {:ok, _} = Supervisor.start_child(pid, {Support.StubServer, on_init: {:ok, nil}})

    assert :ok =
             Reactor.run!(TerminateChildReactor, %{
               supervisor: pid,
               child_id: Support.StubServer,
               fail?: false
             })

    assert %{active: 0, specs: 1} = Supervisor.count_children(pid)
  end

  test "it can restart the child on failure" do
    {:ok, pid} = Supervisor.start_link([], strategy: :one_for_one)
    {:ok, _} = Supervisor.start_child(pid, {Support.StubServer, on_init: {:ok, nil}})

    assert {:error, error} =
             Reactor.run(TerminateChildReactor, %{
               supervisor: pid,
               child_id: Support.StubServer,
               fail?: true
             })

    assert Exception.message(error) =~ ~r/abort/
    assert %{active: 1, specs: 1} = Supervisor.count_children(pid)
  end

  test "it fails verification when `restart_on_undo?` is `true` but the module doesn't support it" do
    assert_raise(Spark.Error.DslError, ~r/does not export/, fn ->
      defmodule FailVerificationReactor do
        @moduledoc false
        use Reactor, extensions: [Reactor.Process]

        terminate_child :terminate_child do
          supervisor value(MyApp.Supervisor)
          child_id value(MyApp.Worker)
          restart_on_undo? true
          module DynamicSupervisor
        end
      end
    end)
  end
end
