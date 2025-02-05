defmodule Reactor.Process do
  @moduledoc """
  An extensions which provides steps for working with supervisors.
  """

  use Spark.Dsl.Extension,
    dsl_patches:
      Enum.map(
        [
          Reactor.Process.Dsl.CountChildren,
          Reactor.Process.Dsl.DeleteChild,
          Reactor.Process.Dsl.ProcessExit,
          Reactor.Process.Dsl.RestartChild,
          Reactor.Process.Dsl.StartChild,
          Reactor.Process.Dsl.StartLink,
          Reactor.Process.Dsl.TerminateChild
        ],
        &%Spark.Dsl.Patch.AddEntity{section_path: [:reactor], entity: &1.__entity__()}
      ),
    transformers: [Reactor.Process.Dsl.Transformer]
end
