defmodule Reactor.Process.Dsl.ProcessExit do
  @moduledoc """
  The `process_exit` DSL entity for the `Reactor.Process` DSL extension.
  """
  alias Reactor.{Dsl.Argument, Dsl.Guard, Dsl.WaitFor, Dsl.Where, Template}

  defstruct __identifier__: nil,
            arguments: [],
            guards: [],
            name: nil,
            process: nil,
            reason: nil,
            timeout: nil,
            wait_for_exit?: false

  @type t :: %__MODULE__{
          __identifier__: any,
          arguments: [Argument.t()],
          guards: [Reactor.Guard.Build.t()],
          name: any,
          process: Template.t(),
          reason: Template.t(),
          timeout: timeout | Template.t(),
          wait_for_exit?: boolean
        }

  @doc false
  def __entity__,
    do: %Spark.Dsl.Entity{
      name: :process_exit,
      describe: """
      Send an exit signal with the given `reason` to `process`.

      See the documentation for `Process.exit/2` for more information.
      """,
      examples: [
        """
        process_exit :exit do
          process result(:server)
          reason value(:kill)
        end
        """
      ],
      target: __MODULE__,
      identifier: :name,
      args: [:name],
      recursive_as: :steps,
      entities: [
        arguments: [WaitFor.__entity__()],
        guards: [Guard.__entity__(), Where.__entity__()]
      ],
      imports: [Argument],
      schema: [
        name: [
          type: :atom,
          required: true,
          doc:
            "A unique name for the step. Used when choosing the return value of the Reactor and for arguments into other steps"
        ],
        description: [
          type: :string,
          required: false,
          doc: "An optional description for the step"
        ],
        process: [
          type: Template.type(),
          required: true,
          doc: "The process to terminate"
        ],
        reason: [
          type: Template.type(),
          required: true,
          doc: "The termination reason"
        ],
        timeout: [
          type: {:or, [:timeout, Template.type()]},
          required: false,
          default: 5_000,
          doc: "How long to wait for the process to terminate before timing out"
        ],
        wait_for_exit?: [
          type: :boolean,
          required: false,
          default: false,
          doc: "Whether to wait until the process exits before continuing"
        ]
      ]
    }
end
