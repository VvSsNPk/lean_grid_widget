import Lean.Data.Json

/-!
# Grids

A rectangular grid of cells stored row-major. Cells are addressed either by `Pos`
(row/column) or by their flat index `r * width + c`, which is what gets sent to the widget.
-/

namespace GridSearch

open Lean

structure Pos where
  row : Nat
  col : Nat
  deriving BEq, Repr, Inhabited, ToJson, FromJson

structure Grid where
  width  : Nat
  height : Nat
  /-- `walls[i]` is `true` when cell `i` is blocked. Size is `width * height`. -/
  walls  : Array Bool
  start  : Nat
  goal   : Nat
  deriving Repr, Inhabited, ToJson, FromJson

namespace Grid

def size (g : Grid) : Nat := g.width * g.height

def toPos (g : Grid) (i : Nat) : Pos := ⟨i / g.width, i % g.width⟩

def toIdx (g : Grid) (p : Pos) : Nat := p.row * g.width + p.col

def isWall (g : Grid) (i : Nat) : Bool := g.walls[i]?.getD true

/-- In-bounds, non-wall orthogonal neighbours, in the order up, right, down, left. -/
def neighbors (g : Grid) (i : Nat) : Array Nat := Id.run do
  let ⟨r, c⟩ := g.toPos i
  let mut out := #[]
  if r > 0 then out := out.push (g.toIdx ⟨r - 1, c⟩)
  if c + 1 < g.width then out := out.push (g.toIdx ⟨r, c + 1⟩)
  if r + 1 < g.height then out := out.push (g.toIdx ⟨r + 1, c⟩)
  if c > 0 then out := out.push (g.toIdx ⟨r, c - 1⟩)
  return out.filter (!g.isWall ·)

/-- Manhattan distance between two cells. -/
def manhattan (g : Grid) (a b : Nat) : Nat :=
  let p := g.toPos a
  let q := g.toPos b
  (if p.row ≥ q.row then p.row - q.row else q.row - p.row) +
  (if p.col ≥ q.col then p.col - q.col else q.col - p.col)

/-- Parse an ASCII map: `#` wall, `S` start, `G` goal, anything else is open.
Rows shorter than the longest row are padded with open cells. -/
def ofStrings (rows : List String) : Grid := Id.run do
  let height := rows.length
  let width := rows.foldl (fun m r => max m r.length) 0
  let mut walls := Array.replicate (width * height) false
  let mut start := 0
  let mut goal := width * height - 1
  for r in [0:height] do
    let row := rows[r]!.toList
    for c in [0:row.length] do
      let i := r * width + c
      match row[c]! with
      | '#' => walls := walls.set! i true
      | 'S' => start := i
      | 'G' => goal := i
      | _ => pure ()
  return { width, height, walls, start, goal }

end Grid
end GridSearch
