import ProofWidgets.Component.HtmlDisplay
import Internship.Search

/-!
# Infoview widget

`GridSearchViz` is a React component (see `widget/gridSearch.js`) that draws the grid and
replays a `SearchResult` step by step. Editing the grid in the infoview calls back into
Lean through the `runSearch` RPC method, so the algorithms always run in Lean.
-/

namespace GridSearch

open Lean Server ProofWidgets
open scoped ProofWidgets.Jsx

structure RunSearchParams where
  grid : Grid
  algo : String
  deriving ToJson, FromJson

@[server_rpc_method]
def runSearch (p : RunSearchParams) : RequestM (RequestTask SearchResult) :=
  RequestM.asTask do
    return search (.ofString p.algo) p.grid

structure GridSearchProps where
  grid : Grid
  algo : String := "bfs"
  /-- Precomputed result for the initial grid, so the first render needs no RPC call. -/
  result : SearchResult
  deriving ToJson, FromJson

@[widget_module]
def GridSearchViz : Component GridSearchProps where
  javascript := include_str ".." / "widget" / "gridSearch.js"

/-- Visualise `alg` on `g`. Use with `#html`. -/
def viz (g : Grid) (alg : Algorithm := .bfs) : Html :=
  <GridSearchViz grid={g} algo={alg.toString} result={search alg g} />

end GridSearch
