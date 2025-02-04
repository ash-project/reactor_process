defmodule Reactor.Process.StartLinkTest do
  @moduledoc false
  use ExUnit.Case, async: true

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

  test "it starts the process" do
    assert {:ok, pid} = Reactor.run(StartLinkReactor, %{fail?: false})
    assert is_pid(pid)
    assert {:links, [^pid]} = Process.info(self(), :links)
  end

  test "it can terminate the process on failure" do
    assert {:links, []} = Process.info(self(), :links)
    assert {:error, _error} = Reactor.run(StartLinkReactor, %{fail?: true})
    assert {:links, []} = Process.info(self(), :links)
  end
end
