defmodule Sim.SimulationLoop do
  use GenServer

  require Logger

  alias Sim.RealmSupervisor

  def start_link(broadcaster, topic, name) do
    GenServer.start_link(__MODULE__, {broadcaster, topic, name},
      name: RealmSupervisor.simulation_loop_module(name)
    )
  end

  def init({broadcaster, topic, name}) do
    Logger.debug("init simulation loop")

    {:ok,
     %{
       next_tick: nil,
       task_ref: nil,
       topic: topic,
       broadcaster: broadcaster,
       task_supervisor_module: RealmSupervisor.task_supervisor_module(name),
       retries: 0
     }}
  end

  def handle_call(:started?, _from, %{next_tick: next_tick} = state) do
    {:reply, not is_nil(next_tick), state}
  end

  def handle_cast({:start, func}, %{next_tick: nil} = state) do
    Logger.info("start sim loop")
    state = Map.put(state, :func, func)
    send(self(), :tick)
    state.broadcaster.broadcast(state.topic, "sim", %{started: true})
    {:noreply, state}
  end

  def handle_cast({:start, _func}, state) do
    # already running
    {:noreply, state}
  end

  def handle_cast(:stop, %{next_tick: nil} = state) do
    # already stopped
    {:noreply, state}
  end

  def handle_cast(:stop, %{next_tick: next_tick} = state) do
    Logger.info("stop sim loop")
    Process.cancel_timer(next_tick)
    state.broadcaster.broadcast(state.topic, "sim", %{started: false})
    {:noreply, %{state | next_tick: nil}}
  end

  def handle_info(:tick, %{task_ref: ref} = state) when is_reference(ref) do
    Logger.warn("the sim task has not yet completed, but is triggered once more -> skipping")
    {:noreply, state}
  end

  def handle_info(:tick, %{task_ref: nil, retries: retries} = state) when retries <= 3 do
    task = Task.Supervisor.async_nolink(state.task_supervisor_module, state.func)
    next_tick = Process.send_after(self(), :tick, 100)
    {:noreply, %{state | next_tick: next_tick, task_ref: task.ref}}
  end

  def handle_info(:tick, %{task_ref: nil, retries: retries} = state) when retries > 3 do
    Logger.warn("more than 3 failed retries, stopping sim loop")
    state.broadcaster.broadcast(state.topic, "sim", %{started: false})
    {:noreply, %{state | next_tick: nil, retries: 0}}
  end

  def handle_info({ref, _answer}, %{task_ref: ref} = state) do
    # The task completed successfully
    # We don't care about the DOWN message now, so let's demonitor and flush it
    Process.demonitor(ref, [:flush])
    {:noreply, %{state | task_ref: nil, retries: 0}}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, %{task_ref: ref} = state) do
    Logger.error("sim task failed!")
    {:noreply, %{state | task_ref: nil, retries: state.retries + 1}}
  end
end
