import Internship.Grid

/-!
# Search algorithms on grids

All algorithms share one loop: keep a frontier of discovered cells, repeatedly pick one
to expand, and push its unexplored neighbours. They differ only in *which* frontier
entry gets picked (`Algorithm.pick`).

Instead of recording a snapshot per step, a run records for each cell the step at which it
entered the frontier (`openedAt`) and the step at which it was expanded (`closedAt`).
Any intermediate frame can be rebuilt from these: at step `k` a cell is expanded if
`closedAt ≤ k`, and on the frontier if `openedAt ≤ k < closedAt`.
-/

namespace GridSearch

open Lean

inductive Algorithm where
  | bfs | dfs | greedy | astar
  deriving BEq, Repr, Inhabited

namespace Algorithm

def ofString : String → Algorithm
  | "dfs" => .dfs
  | "greedy" => .greedy
  | "astar" => .astar
  | _ => .bfs

def toString : Algorithm → String
  | .bfs => "bfs" | .dfs => "dfs" | .greedy => "greedy" | .astar => "astar"

/-- Whether a cheaper path to a cell already on the frontier replaces the old entry. -/
def relaxes : Algorithm → Bool
  | .astar => true
  | _ => false

end Algorithm

/-- A frontier entry. `seq` is the insertion counter, used for FIFO/LIFO order and tie-breaking. -/
structure Entry where
  cell : Nat
  cost : Nat
  heur : Nat
  seq  : Nat
  deriving Inhabited

/-- Whether `a` should be expanded before `b`. -/
def Algorithm.before : Algorithm → Entry → Entry → Bool
  | .bfs,    a, b => a.seq < b.seq
  | .dfs,    a, b => a.seq > b.seq
  | .greedy, a, b => a.heur < b.heur || (a.heur == b.heur && a.seq < b.seq)
  | .astar,  a, b =>
    let fa := a.cost + a.heur
    let fb := b.cost + b.heur
    fa < fb || (fa == fb && (a.heur < b.heur || (a.heur == b.heur && a.seq > b.seq)))

/-- Index of the frontier entry to expand next. Linear scan: grids here are small. -/
def Algorithm.pick (alg : Algorithm) (frontier : Array Entry) : Nat := Id.run do
  let mut best := 0
  for i in [1:frontier.size] do
    if alg.before frontier[i]! frontier[best]! then best := i
  return best

structure SearchResult where
  /-- Step at which each cell entered the frontier, or `-1`. -/
  openedAt : Array Int
  /-- Step at which each cell was expanded, or `-1`. -/
  closedAt : Array Int
  /-- Number of expansions performed. -/
  steps : Nat
  found : Bool
  /-- Cells from start to goal, empty when `found = false`. -/
  path : Array Nat
  deriving Repr, Inhabited, ToJson, FromJson

def search (alg : Algorithm) (g : Grid) : SearchResult := Id.run do
  let n := g.size
  let mut openedAt : Array Int := Array.replicate n (-1)
  let mut closedAt : Array Int := Array.replicate n (-1)
  let mut parent : Array (Option Nat) := Array.replicate n none
  let mut bestCost : Array Nat := Array.replicate n 0
  let mut frontier : Array Entry := #[]
  let mut seq := 0
  let mut step : Nat := 0
  let mut found := false
  if g.start < n && !g.isWall g.start then
    frontier := #[⟨g.start, 0, g.manhattan g.start g.goal, 0⟩]
    openedAt := openedAt.set! g.start 0
    seq := 1
  -- Each cell is expanded at most once, so `n` iterations always suffice.
  for _ in [0:n] do
    if frontier.isEmpty then break
    let i := alg.pick frontier
    let e := frontier[i]!
    frontier := frontier.eraseIdx! i
    closedAt := closedAt.set! e.cell (step : Int)
    if e.cell == g.goal then
      found := true
      break
    for nb in g.neighbors e.cell do
      if closedAt[nb]! ≥ 0 then continue
      let cost := e.cost + 1
      if openedAt[nb]! ≥ 0 then
        -- Already on the frontier: only A* replaces it, and only with a cheaper path.
        if !(alg.relaxes && cost < bestCost[nb]!) then continue
        frontier := frontier.filter (·.cell != nb)
      else
        openedAt := openedAt.set! nb ((step + 1 : Nat) : Int)
      parent := parent.set! nb (some e.cell)
      bestCost := bestCost.set! nb cost
      frontier := frontier.push ⟨nb, cost, g.manhattan nb g.goal, seq⟩
      seq := seq + 1
    step := step + 1
  -- Walk parents back from the goal.
  let mut path := #[]
  if found then
    let mut cur := g.goal
    path := #[cur]
    for _ in [0:n] do
      match parent[cur]! with
      | some p => cur := p; path := path.push cur
      | none => break
    path := path.reverse
  return { openedAt, closedAt, steps := step + (if found then 1 else 0), found, path }

end GridSearch
