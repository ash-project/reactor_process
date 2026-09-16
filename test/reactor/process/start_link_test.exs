# SPDX-FileCopyrightText: 2025 reactor_process contributors <https://github.com/ash-project/reactor_process/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule Reactor.Process.StartLinkTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Reactor.Process.Step.StartLink

  defmodule StartLinkReactor do
    @moduledoc false
    use Reactor, extensions: [Reactor.Process]

    input :fail?

    start_link :stub_server do
      child_spec({Support.StubServer, [on_init: {:ok, nil}]})
    end

    flunk :fail, "abort" do
      wait_for :stub_server
      argument :fail?, input(:fail?)

      where & &1.arguments.fail?
    end

    return :stub_server
  end

  defmodule ReuseLinkReactor do
    @moduledoc false
    use Reactor, extensions: [Reactor.Process]

    input :fail?
    input :child_spec

    start_link :stub_server do
      child_spec(input(:child_spec))
      fail_on_already_started? false
      fail_on_ignore? false
    end

    flunk :fail, "abort" do
      wait_for :stub_server
      argument :fail?, input(:fail?)

      where & &1.arguments.fail?
    end

    return :stub_server
  end

  test "it starts the process" do
    assert {:ok, %StartLink.Result{pid: pid, started?: true}} =
             Reactor.run(StartLinkReactor, %{fail?: false})

    assert is_pid(pid)
    assert {:links, [^pid]} = Process.info(self(), :links)
  end

  test "it can terminate the process on failure" do
    assert {:links, []} = Process.info(self(), :links)
    assert {:error, _error} = Reactor.run(StartLinkReactor, %{fail?: true})
    assert {:links, []} = Process.info(self(), :links)
  end

  test "it returns an already started process with `started?: false` and does not link to it" do
    {existing, child_spec} = start_named_stub_server()

    assert {:ok, %StartLink.Result{pid: ^existing, started?: false}} =
             Reactor.run(ReuseLinkReactor, %{child_spec: child_spec, fail?: false})

    assert {:links, []} = Process.info(self(), :links)
    GenServer.stop(existing)
  end

  test "it does not terminate an already started process on failure" do
    {existing, child_spec} = start_named_stub_server()

    assert {:error, error} =
             Reactor.run(ReuseLinkReactor, %{child_spec: child_spec, fail?: true})

    assert Exception.message(error) =~ ~r/abort/
    assert Process.alive?(existing)
    assert {:links, []} = Process.info(self(), :links)
    GenServer.stop(existing)
  end

  test "it returns `pid: nil` when the start function returns `:ignore`" do
    assert {:ok, %StartLink.Result{pid: nil, started?: false}} =
             Reactor.run(ReuseLinkReactor, %{
               child_spec: {Support.StubServer, on_init: :ignore},
               fail?: false
             })
  end

  test "it rolls back cleanly when the start function returned `:ignore`" do
    assert {:error, error} =
             Reactor.run(ReuseLinkReactor, %{
               child_spec: {Support.StubServer, on_init: :ignore},
               fail?: true
             })

    assert Exception.message(error) =~ ~r/abort/
  end

  test "`can?/2` treats a bare module as undoable" do
    step = Reactor.Builder.new_step!(:start_link, StartLink)

    assert Reactor.Step.can?(step, :undo)
  end

  defp start_named_stub_server do
    name = :"stub_server_#{System.unique_integer([:positive])}"
    {:ok, existing} = GenServer.start(Support.StubServer, [on_init: {:ok, nil}], name: name)

    {existing, {Support.StubServer, on_init: {:ok, nil}, name: name}}
  end
end
