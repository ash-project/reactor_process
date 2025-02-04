defmodule Reactor.Process.Step.ProcessExit do
  @arg_schema Spark.Options.new!(
                process: [
                  type: :pid,
                  required: true,
                  doc: "The process to terminate"
                ],
                reason: [
                  type: :any,
                  required: true,
                  doc: "The termination reason"
                ],
                timeout: [
                  type: :timeout,
                  required: false,
                  default: 5_000,
                  doc: "How long to wait for the process to terminate before timing out"
                ]
              )

  @opt_schema Spark.Options.new!(
                wait_for_exit?: [
                  type: :boolean,
                  required: false,
                  default: false,
                  doc: "Whether to wait for the process to exit before continuing"
                ]
              )

  @moduledoc """
  A Reactor step which sends an exit signal to the process.

  When the `wait_for_exit?` option is `true` the step will monitor the process
  until it exits or times out.

  ## Arguments

  #{Spark.Options.docs(@arg_schema)}

  ## Options

  #{Spark.Options.docs(@opt_schema)}
  """
  use Reactor.Step
  import Reactor.Process.Utils

  @doc false
  @impl true
  def run(arguments, context, options) do
    with {:ok, arguments} <- Spark.Options.validate(Enum.to_list(arguments), @arg_schema),
         {:ok, options} <- Spark.Options.validate(options, @opt_schema),
         {:ok, process} <- Keyword.fetch(arguments, :process),
         {:ok, reason} <- Keyword.fetch(arguments, :reason) do
      if options[:wait_for_exit?] do
        case terminate(process, reason, arguments[:timeout], context.current_step) do
          :ok -> {:ok, reason}
          {:error, reason} -> {:error, reason}
        end
      else
        Process.exit(process, reason)
        {:ok, reason}
      end
    end
  end
end
