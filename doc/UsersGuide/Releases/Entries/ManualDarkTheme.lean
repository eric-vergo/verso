/-
Copyright (c) 2026 Lean FRO LLC. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Eric Vergo
-/
module

public import UsersGuide.Releases.Entry

open Verso.Genre Manual InlineLean UsersGuide.Releases

release_note
  version := ⟨4, 36, 0⟩
  breaking := false
  tag := "feat-manual-dark-theme"
  prs := []

#doc (Manual) "Dark Theme for Manuals" =>

HTML output from the manual genre now has a dark theme, which follows the reader's system color scheme by default and can be chosen explicitly with a control in the table of contents.

The control at the foot of the table of contents chooses between the light theme, the dark theme, and following the system's color scheme ("Auto", the default).
The choice is stored in the browser's local storage under the key `verso-theme` and applied before the page is first painted.
An explicit choice is recorded as `data-theme="light"` or `data-theme="dark"` on the root element; other scripts may set the same attribute and storage key, and the control follows them.

The dark theme consists of dark values for the color variables documented in `verso-vars.css` and `book.css`, so sites that customize colors can provide their own dark values for the selectors `html[data-theme="dark"]` and, inside `@media (prefers-color-scheme: dark)`, `html:not([data-theme="light"])`.
Colors that were previously fixed in the manual's stylesheets can now be customized with the variables `--verso-background-color`, `--verso-header-shadow-color`, `--verso-toc-link-color`, `--verso-toc-link-hover-color`, `--verso-toc-triangle-color`, and `--verso-docstring-border-color`; the defaults keep the previous light appearance.
