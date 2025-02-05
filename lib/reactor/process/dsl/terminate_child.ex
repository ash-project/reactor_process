defmodule Reactor.Process.Dsl.TerminateChild do
  @moduledoc """
  A `terminate_child` DSL entity for the `Reactor.Process` DSL extension.
  """
  alias Reactor.{
    Dsl.Argument,
    Dsl.Guard,
    Dsl.WaitFor,
    Dsl.Where,
    Template
  }

  defstruct __identifier__: nil,
            arguments: [],
            child_id: nil,
            description: nil,
            fail_on_not_found?: true,
            guards: [],
            module: Supervisor,
            name: nil,
            restart_on_undo?: true,
            supervisor: nil

  @type t :: %__MODULE__{
          __identifier__: any,
          arguments: [Argument.t()],
          child_id: Template.t(),
          description: nil | String.t(),
          fail_on_not_found?: boolean,
          guards: [Reactor.Guard.Build.t()],
          module: module,
          name: any,
          restart_on_undo?: boolean,
          supervisor: Template.t() | Supervisor.supervisor()
        }

  @doc false
  def __entity__,
    do: %Spark.Dsl.Entity{
      name: :terminate_child,
      describe: """
      Terminates the given child identified by `child_id`.

      See the documentation for `Supervisor.terminate_child/2` for more information.

      ## Restarting

      When the reactor is undoing changes, it is possible for this step to restart
      the terminated child using `restart_child/2`. Be aware that this will only
      work if the child spec hasn't subsequently been deleted by another step and
      the `restart_child/2` function is present on the module (ie not
      `DynamicSupervisor`).

      > #### Child ID {: .tip}
      >
      > The `child_id` argument can take either a traditional child ID (for a
      > traditional `Supervisor`) or a PID (for a `DynamicSupervisor`). It's up to
      > you to make sure you provide the correct inputs.
      """,
      examples: [
        """
        terminate_child :terminate_child do
          supervisor input(:supervisor)
          child_id input(:child_id)
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
        child_id: [
          type: Template.type(),
          required: true,
          doc: "The ID for the child spec to remove"
        ],
        fail_on_not_found?: [
          type: :boolean,
          required: false,
          default: true,
          doc: "Whether the step should fail if the no child is found under the `child_id`"
        ],
        restart_on_undo?: [
          type: :boolean,
          required: false,
          default: false,
          doc: "Whether to terminate the started process when the Reactor is undoing changes"
        ]
      ]
    }
end
