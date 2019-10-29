defmodule Sim.RealmSupervisor do
  use Supervisor

  def start_link(name, broadcaster) do
    Supervisor.start_link(__MODULE__, {name, broadcaster}, name: name)
  end

  def init({name, broadcaster}) do
    children = [
      %{
        id: realm_module(name),
        start:
          {Sim.Realm, :start_link,
           [
             [
               name: realm_module(name),
               supervisor_module: root_supervisor_module(name)
             ]
           ]}
      },
      {DynamicSupervisor, name: root_supervisor_module(name), strategy: :one_for_one},
      {Task.Supervisor, name: task_supervisor_module(name)},
      %{
        id: simulation_loop_module(name),
        start: {Sim.SimulationLoop, :start_link, [broadcaster, topic(name), name]}
      },
      {DynamicSupervisor, name: object_supervisor_module(name), strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  defp topic(name) do
    name |> Atom.to_string() |> String.replace_leading("Elixir.", "")
  end

  def simulation_loop_module(name) do
    Module.concat(name, "SimulationLoop")
  end

  def realm_module(name) do
    Module.concat(name, "Realm")
  end

  def root_supervisor_module(name) do
    Module.concat(name, "RootSupervisor")
  end

  def object_supervisor_module(name) do
    Module.concat(name, "ObjectSupervisor")
  end

  def task_supervisor_module(name) do
    Module.concat(name, "SimTaskSupervisor")
  end
end
