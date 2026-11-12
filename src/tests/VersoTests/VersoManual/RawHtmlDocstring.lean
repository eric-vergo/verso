/-
Released under Apache 2.0 license as described in the file LICENSE.
-/
import Errata
import VersoManual

namespace RawHtmlDocstringRegression

open Errata
open Verso Output Genre Manual

/-- Says `"Not available yet: <title>"` for an unknown <title> or <b>bold</b> text. -/
def rawHtmlFixture : Nat := 0

/-- A structure whose field docstring has an unclosed tag. -/
structure RawHtmlFields where
  /-- Takes the <name> of the thing. -/
  field : Nat

#docs (Manual) doc "Raw HTML in docstrings" :=
:::::::

{docstring rawHtmlFixture}

{docstring RawHtmlFields}

:::::::

private def hasSubstring (s sub : String) : Bool :=
  s.find? sub |>.isSome

private def renderDoc : IO String := do
  let rendered ← IO.mkRef ""
  let exitCode ← withLogger fun logger => do
    let cfg : RenderConfig := {}
    let (part, state) ← (traverseHtmlSingle cfg doc.toPart).run extension_impls% |>.run logger
    let ctxt : Manual.TraverseContext := {}
    let definitionIds := state.definitionIds ctxt
    let remotes : Multi.AllRemotes := {}
    let linkTargets := cfg.linkTargets state remotes
    let (html, _) ←
      (Manual.toHtml (m := ReaderT Multi.AllRemotes (ReaderT ExtensionImpls (BuildLogT IO)))
          {} ctxt state definitionIds linkTargets {} part).run {}
        |>.run remotes
        |>.run extension_impls%
        |>.run logger
    rendered.set html.asString
  unless exitCode == 0 do
    throw <| IO.userError "Manual docstring HTML rendering logged errors"
  rendered.get

/-- Raw inline HTML in a docstring renders as its text, escaped, instead of crashing Lean. -/
@[test]
def rawInlineHtmlIsText : Test := do
  let html ← renderDoc
  assertTrue (hasSubstring html "for an unknown &lt;title&gt; or &lt;b&gt;bold&lt;/b&gt; text")
    "inline HTML in a declaration docstring should render as escaped text"
  assertTrue (hasSubstring html "Takes the &lt;name&gt; of the thing.")
    "inline HTML in a field docstring should render as escaped text"
