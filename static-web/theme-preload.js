/**
 * Copyright (c) 2026 Lean FRO LLC. All rights reserved.
 * Released under Apache 2.0 license as described in the file LICENSE.
 * Author: Eric Vergo
 */

// Enable TypeScript checking.
// @ts-check

// Applies a saved color theme before the first paint.
//
// This is the inline counterpart to theme-toggle.js: it runs in the page head so that a reader
// who chose a theme does not see the page flash in the system's theme first. A saved choice of
// "light" or "dark" becomes the root element's data-theme attribute; without one, the stylesheet
// follows the system's color scheme. Keep the storage key in sync with theme-toggle.js.

(function () {
    try {
        const saved = localStorage.getItem("verso-theme");
        if (saved === "light" || saved === "dark") {
            document.documentElement.setAttribute("data-theme", saved);
        }
    } catch (_) {
        // Follow the system's color scheme when local storage is unavailable.
    }
})();
