import Internship.Widget

/-!
# Grid search demo

Put the cursor on a `#html` line to see the widget in the infoview.
Pick an algorithm, draw walls by clicking and dragging, and move the start and goal.
Each edit runs the search again in Lean.
-/

open GridSearch ProofWidgets

def maze : Grid := .ofStrings [
  "....................",
  ".S.......#..........",
  ".........#..........",
  "..######.#.#######..",
  ".......#.#.......#..",
  ".......#.#######.#..",
  ".......#.........#..",
  ".......###########..",
  "...............#....",
  "...............#..G.",
  "...............#....",
  "...................."
]

#html viz maze .bfs
#html viz maze .astar

-- The algorithms are plain Lean functions, so they can also be evaluated directly.
#eval (search .bfs maze).path.size - 1
#eval (search .astar maze).steps
