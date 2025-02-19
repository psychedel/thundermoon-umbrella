defmodule Thundermoon.GameOfLife.Simulation do
  alias Sim.Torus, as: Grid

  def sim(grid) do
    Grid.create(Grid.width(grid), Grid.height(grid), &sim_cell(grid, &1, &2))
  end

  def sim_cell(grid, x, y) do
    look_around(grid, x, y)
    |> neighbours()
    |> new_state(Grid.get(grid, x, y))
  end

  # https://de.wikipedia.org/wiki/Conways_Spiel_des_Lebens#Die_Spielregeln
  def new_state(neighbours, active) do
    case {neighbours, active} do
      {3, false} -> true
      {neighbours, true} when neighbours < 2 -> false
      {neighbours, true} when neighbours > 3 -> false
      {_, state} -> state
    end
  end

  def neighbours(cells) do
    Enum.reduce(cells, 0, fn cell, acc ->
      if cell, do: acc + 1, else: acc
    end)
  end

  def look_around(grid, x, y) do
    Enum.map(-1..1, fn rx ->
      Enum.map(-1..1, fn ry ->
        case {rx, ry} do
          {0, 0} -> false
          {rx, ry} -> Grid.get(grid, x + rx, y + ry)
        end
      end)
    end)
    |> List.flatten()
  end
end
