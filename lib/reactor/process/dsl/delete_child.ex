defmodule Reactor.Process.Dsl.DeleteChild do
  @moduledoc """
  A `delete_child` DSL entity for the `Reactor.Process` DSL extension.
  """
  alias Reactor.{Dsl.Argument, Dsl.Guard, Dsl.WaitFor, Dsl.Where, Template}

  defstruct __identifier__: nil,
            arguments: [],
            child_id: nil,
            description: nil,
            guards: [],
            module: Supervisor,
            name: nil,
            supervisor: nil

  @type t :: %__MODULE__{
          __identifier__: any,
          arguments: [Argument.t()],
          child_id: Template.t(),
          description: nil | String.t(),
          guards: [Reactor.Guard.Build.t()],
          module: module,
          name: any,
          supervisor: Template.t()
        }

  @doc false
  def __entity__,
    do: %Spark.Dsl.Entity{
      name: :delete_child,
      describe: """
      Deletes a child specification by id from a Supervisor.

      See the documentation for `Supervisor.delete_child/2` for more information.
      """,
      examples: [
        """
        delete_child :delete_child do
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
          doc: "The module to use. Must export `count_children/1`"
        ],
        child_id: [
          type: Template.type(),
          required: true,
          doc: "The ID for the child spec to remove"
        ]
      ]
    }
end
