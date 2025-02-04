defmodule Reactor.Process.Dsl.StartLink do
  @moduledoc """
  The `start_link` DSL entity for the `Reactor.Process` DSL extension.
  """
  alias Reactor.{Dsl.Argument, Dsl.Guard, Dsl.WaitFor, Dsl.Where, Process.Dsl.ChildSpec, Template}

  defstruct __identifier__: nil,
            arguments: [],
            child_spec: nil,
            description: nil,
            fail_on_already_started?: true,
            fail_on_ignore?: true,
            guards: [],
            name: nil,
            terminate_on_undo?: true,
            termination_reason: :normal,
            termination_timeout: 5_000

  @type t :: %__MODULE__{
          __identifier__: any,
          arguments: [Argument.t()],
          child_spec: Template.t(),
          description: nil | String.t(),
          fail_on_already_started?: boolean,
          fail_on_ignore?: boolean,
          guards: [Reactor.Guard.Build.t()],
          name: any,
          terminate_on_undo?: boolean,
          termination_reason: any,
          termination_timeout: timeout
        }

  @doc false
  def __entity__,
    do: %Spark.Dsl.Entity{
      name: :start_link,
      describe: """
      Starts a process which is linked to the process running the Reactor.

      See the documentation for `Reactor.Process.Step.StartLink` for more information.
      """,
      examples: [
        """
        start_link :supervisor do
          child_spec {Supervisor, name: __MODULE__.Supervisor})
        end
        """,
        """
        input :initial_value

        start_link :agent do
          child_spec result(:value), transform: &{Agent, fn -> &1 end}
        end
        """
      ],
      target: __MODULE__,
      identifier: :name,
      args: [:name],
      recursive_as: :steps,
      entities: [
        arguments: [WaitFor.__entity__()],
        child_spec: [ChildSpec.__entity__()],
        guards: [Guard.__entity__(), Where.__entity__()]
      ],
      singleton_entity_keys: [:child_spec],
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
        fail_on_already_started?: [
          type: :boolean,
          required: false,
          default: true,
          doc:
            "Whether the step should fail if the start function returns an already started error"
        ],
        fail_on_ignore?: [
          type: :boolean,
          required: false,
          default: true,
          doc: "Whether the step should fail if the start function returns `:ignore`"
        ],
        terminate_on_undo?: [
          type: :boolean,
          required: false,
          default: true,
          doc: "Whether to terminate the started process when the Reactor is undoing changes"
        ],
        termination_reason: [
          type: :any,
          required: false,
          default: :kill,
          doc: "The reason to give to the process when terminating it"
        ],
        termination_timeout: [
          type: :timeout,
          required: false,
          default: 5_000,
          doc: "How long to wait for a process to terminate"
        ]
      ]
    }
end
