# SPDX-FileCopyrightText: 2025 reactor_process contributors <https://github.com/ash-project/reactor_process/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule Reactor.Process.StartChildTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Reactor.Process.Step.StartChild

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

  test "`can?/2` treats a bare module as undoable" do
    step = Reactor.Builder.new_step!(:start_child, StartChild)

    assert Reactor.Step.can?(step, :undo)
  end

  test "`can?/2` treats a module with no `terminate_on_undo?` option as undoable" do
    step = Reactor.Builder.new_step!(:start_child, {StartChild, []})

    assert Reactor.Step.can?(step, :undo)
  end

  test "`can?/2` honours `terminate_on_undo?: false`" do
    step = Reactor.Builder.new_step!(:start_child, {StartChild, terminate_on_undo?: false})

    refute Reactor.Step.can?(step, :undo)
  end

  test "a builder-built step with a bare module terminates the child on reactor failure" do
    {:ok, pid} = Supervisor.start_link([], strategy: :one_for_one)

    assert {:error, _error} =
             StartChild
             |> failing_builder_reactor()
             |> Reactor.run(%{
               supervisor: pid,
               child_spec: {Support.StubServer, on_init: {:ok, nil}}
             })

    assert_received {:child, child}
    refute Process.alive?(child)
    assert %{active: 0} = Supervisor.count_children(pid)
  end

  test "a builder-built step with no `terminate_on_undo?` option terminates the child on reactor failure" do
    {:ok, pid} = Supervisor.start_link([], strategy: :one_for_one)

    assert {:error, _error} =
             {StartChild, []}
             |> failing_builder_reactor()
             |> Reactor.run(%{
               supervisor: pid,
               child_spec: {Support.StubServer, on_init: {:ok, nil}}
             })

    assert_received {:child, child}
    refute Process.alive?(child)
    assert %{active: 0} = Supervisor.count_children(pid)
  end

  defp failing_builder_reactor(impl) do
    test_pid = self()

    Reactor.Builder.new()
    |> Reactor.Builder.add_input!(:supervisor)
    |> Reactor.Builder.add_input!(:child_spec)
    |> Reactor.Builder.add_step!(:start_child, impl,
      supervisor: {:input, :supervisor},
      child_spec: {:input, :child_spec}
    )
    |> Reactor.Builder.add_step!(
      :fail,
      {Reactor.Step.AnonFn,
       run: fn %{child: child} ->
         send(test_pid, {:child, child})
         {:error, "abort"}
       end},
      child: {:result, :start_child}
    )
    |> Reactor.Builder.return!(:start_child)
  end
end
