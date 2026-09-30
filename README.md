# Interactive Grid Search in the Lean 4 Infoview

**Pathfinding algorithms written in Lean 4, drawn as an interactive React app inside VS Code, using [ProofWidgets4](https://github.com/leanprover-community/ProofWidgets4).**

![Grid search widget running in the Lean infoview in VS Code](docs/screenshot.png)

Most people know Lean 4 as a theorem prover. It is also a general-purpose programming language, and its VS Code extension can render custom UI. This project uses that to show BFS, DFS, Greedy best-first and A* running step by step on a grid you can edit, right next to the code.

---

## What it does

- Put your cursor on a `#html viz maze .bfs` line and the **Lean InfoView** panel shows a live grid.
- **Pick an algorithm** from the dropdown: Breadth-first, Depth-first, Greedy best-first or A*.
- **Edit the maze**: click and drag to draw walls, move the start and goal, clear or reset.
- **Replay the search** frame by frame, with play/pause, step controls, a scrubber and a speed setting.
- **Watch the stats**: step count, expanded cells, frontier size and final path length.

Every edit sends the new grid back to Lean over RPC. **The algorithms always run in Lean**; the JavaScript only draws the result.

---

## Why Lean 4 ProofWidgets?

[ProofWidgets4](https://github.com/leanprover-community/ProofWidgets4) lets you embed React components in the Lean infoview, the panel that usually shows proof goals. With it you can:

- **Write UI next to your code.** `#html` renders a component inline; no separate web server or frontend build.
- **Call Lean from the browser.** A `@[server_rpc_method]` function becomes something JavaScript can call, so the UI stays in sync with real Lean code.
- **Pass data through typed JSON.** Lean structures derive `ToJson`/`FromJson` and arrive in React as props.

The same mechanism powers interactive proof tools in Mathlib. Here it's used to build a small algorithm visualiser.

---

## How it works

```
 Demo.lean                 Widget.lean                  widget/gridSearch.js
 ─────────                 ───────────                  ────────────────────
 #html viz maze .bfs  ──►  viz : Grid → Html      ──►   React component (props:
                           runSearch (RPC)  ◄──────     grid, algo, result)
                               │                         draws grid, replays steps
                               ▼
                           Search.lean: search alg grid → SearchResult
```

| File | Role |
| --- | --- |
| `Internship/Grid.lean` | Grid type, neighbours, Manhattan distance, ASCII map parser (`#` wall, `S` start, `G` goal) |
| `Internship/Search.lean` | One search loop shared by all four algorithms; they differ only in which frontier entry they expand next |
| `Internship/Widget.lean` | The ProofWidgets component, the `runSearch` RPC method and the `viz` helper |
| `widget/gridSearch.js` | React UI: grid editor, playback controls, legend |
| `Internship/Demo.lean` | Open this file to try it |

The search doesn't store a snapshot per step. It records when each cell **entered the frontier** and when it was **expanded**, and the widget rebuilds any frame from those two arrays. That keeps the data sent to the UI small and makes scrubbing instant.

---

## Try it yourself

### Requirements

- [VS Code](https://code.visualstudio.com/)
- The [**Lean 4 VS Code extension**](https://marketplace.visualstudio.com/items?itemName=leanprover.lean4), which installs `elan`/`lake` and provides the InfoView
- Git

### Steps

```bash
git clone https://github.com/VvSsNPk/lean_grid_widget.git
cd lean_grid_widget
lake build           # fetches ProofWidgets4 and builds the project
code .
```

1. Open `Internship/Demo.lean`.
2. Open the InfoView if it isn't showing (`Ctrl+Shift+Enter`, or **Lean 4: Toggle Infoview** in the command palette).
3. Put your cursor on `#html viz maze .bfs` or `#html viz maze .astar`.
4. Draw walls, switch algorithms and press ▶.

You can also use the algorithms as plain Lean functions:

```lean
#eval (search .bfs maze).path.size - 1   -- shortest path length
#eval (search .astar maze).steps         -- how many cells A* expanded
```

Make your own maze with `Grid.ofStrings`:

```lean
def myMaze : Grid := .ofStrings [
  "S...#....",
  ".##.#.##.",
  "....#...G"
]

#html viz myMaze .astar
```

---

## Built with

- **Lean 4** (`v4.35.0-rc3`)
- **ProofWidgets4** (`v0.0.114`)
- **VS Code** + the Lean 4 extension
- **[Claude Code](https://claude.com/claude-code)**: the project was written together with Claude in the VS Code extension (visible in the screenshot)

---

## Ideas for next steps

- Add Dijkstra with weighted cells
- Prove properties of the search in Lean, such as "BFS returns a shortest path"
- Diagonal moves and other heuristics
- Side-by-side comparison of two algorithms on the same maze

If you're exploring Lean 4 beyond theorem proving, or want to see what ProofWidgets can do, feel free to star the repo, fork it or open an issue.
