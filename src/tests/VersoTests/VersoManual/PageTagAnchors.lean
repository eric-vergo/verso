/-
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Errata
import VersoManual

namespace PageTagAnchorsRegression

open Errata
open Verso Output Genre Manual

#docs (Manual) doc "Page tags" :=
:::::::

Intro.

# First Chapter
%%%
tag := "first-chapter"
htmlSplit := .never
%%%

Text of the first chapter.

## A Section
%%%
tag := "first-section"
%%%

Text of its section.

# Second Chapter
%%%
tag := "second-chapter"
%%%

Text of the second chapter.

:::::::

private def hasSubstring (s sub : String) : Bool :=
  s.find? sub |>.isSome

/-- Renders `doc` as multi-page HTML under `dir`. -/
private def renderSite (dir : System.FilePath) : IO Unit := do
  let exitCode ← withLogger fun logger => do
    let cfg : RenderConfig := { destination := dir }
    let (part, state) ← (traverseHtmlMulti cfg doc.toPart).run extension_impls% |>.run logger
    emitXrefsJson (dir / "html-multi") state
    (emitHtmlMulti cfg part state).run extension_impls% |>.run logger
  unless exitCode == 0 do
    throw <| IO.userError "Multi-page HTML rendering logged errors"

/--
A page's own tag is the `id` of its title, so the links to it (`First-Chapter/#first-chapter`,
from the table of contents) land on an element, as a section's links do.
-/
@[test]
def pageTitleCarriesItsTag : Test := do
  let dir : System.FilePath := s!"/tmp/verso-page-tags-{← IO.monoNanosNow}"
  try
    renderSite dir
    let root ← IO.FS.readFile (dir / "html-multi" / "index.html")
    let first ← IO.FS.readFile (dir / "html-multi" / "First-Chapter" / "index.html")
    let second ← IO.FS.readFile (dir / "html-multi" / "Second-Chapter" / "index.html")
    assertTrue (hasSubstring root "First-Chapter/#first-chapter")
      "the table of contents links to the page's tag"
    assertTrue (hasSubstring first "<h1 id=\"first-chapter\">")
      "the first chapter's page title carries its tag"
    assertTrue (hasSubstring second "<h1 id=\"second-chapter\">")
      "the second chapter's page title carries its tag"
    assertTrue (hasSubstring first "id=\"first-section\"")
      "a section header on the page keeps its tag"
  finally
    try IO.FS.removeDirAll dir catch _ => pure ()

end PageTagAnchorsRegression
