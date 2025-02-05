defmodule Reactor.Process.Dsl.StartChild do
  @moduledoc """
  A `start_child` DSL entity for the `Reactor.Process` DSL extension.
  """
  alias Reactor.{Dsl.Argument, Dsl.Guard, Dsl.WaitFor, Dsl.Where, Process.Dsl.ChildSpec, Template}

  defstruct __identifier__: nil,
            arguments: [],
            child_spec: nil,
            description: nil,
            fail_on_already_present?: true,
            fail_on_already_started?: true,
            guards: [],
            module: Supervisor,
            name: nil,
            supervisor: nil,
            terminate_on_undo?: true,
            termination_reason: :normal,
            termination_timeout: 5_000

  @type t :: %__MODULE__{
          __identifier__: any,
          arguments: [Argument.t()],
          child_spec: ChildSpec.t(),
          description: nil | String.t(),
          fail_on_already_present?: boolean,
          fail_on_already_started?: boolean,
          guards: [Reactor.Guard.Build.t()],
          module: module,
          name: any,
          supervisor: Template.t() | Supervisor.supervisor(),
          terminate_on_undo?: boolean,
          termination_reason: any,
          termination_timeout: timeout
        }

  @doc false
  def __entity__,
    do: %Spark.Dsl.Entity{
      name: :start_child,
      describe: """
      Adds a child specification to a supervisor and starts that child.

      See the documentation for `Supervisor.start_child/2` for more information.
      """,
      examples: [
        """
        start_link :supervisor do
          child_spec value({Supervisor, strategy: :one_for_one}
        end

        start_child :worker do
          supervisor result(:supervisor)
          child_spec value({Agent, initial_value: 0})
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
        supervisor: [
          type:
            {:or,
             [
               Template.type(),
               :pid,
               :atom,
               {:tuple, [{:literal, :global}, :any]},
               {:tuple, [{:literal, :via}, :module, :any]},
               {:tuple, [:atom, :atom]}
             ]},
          required: true,
          doc: "The supervisor to query"
        ],
        module: [
          type: :module,
          required: false,
          default: Supervisor,
          doc: "The module to use. Must export `start_child/2`"
        ],
        fail_on_already_present?: [
          type: :boolean,
          required: false,
          default: true,
          doc:
            "Whether the step should fail if the child spec is already present in the supervisor"
        ],
        fail_on_already_started?: [
          type: :boolean,
          required: false,
          default: true,
          doc:
            "Whether the step should fail if the start function returns an already started error"
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
