/**
 * Copyright (c) 2026 Lean FRO LLC. All rights reserved.
 * Released under Apache 2.0 license as described in the file LICENSE.
 * Author: Eric Vergo
 */

// Enable TypeScript checking.
// @ts-check

// The color theme control.
//
// The colors themselves are determined entirely by CSS (see
// src/verso-manual/VersoManual/Html/Style.lean): the page follows the system's color scheme
// unless the root element's data-theme attribute is "light" or "dark". This script makes the
// control in the table of contents (the element with the data-verso-theme-toggle attribute)
// choose between the two themes and the system's scheme ("auto"), and stores the choice in
// localStorage under "verso-theme". The inline theme-preload.js applies a stored choice before
// the first paint; keep the storage key in sync with it.
//
// Other scripts may also set data-theme and the same storage key (for example, a site's own
// theme switch). The control reflects such changes, and changes made in other tabs.

(function () {
    const STORAGE_KEY = "verso-theme";

    /**
     * The current choice: "light" or "dark" if one is set on the root element, else "auto".
     * @returns {string}
     */
    function currentChoice() {
        const theme = document.documentElement.getAttribute("data-theme");
        return theme === "light" || theme === "dark" ? theme : "auto";
    }

    /**
     * Applies a choice to the page.
     * @param {string} choice
     */
    function apply(choice) {
        const root = document.documentElement;
        if (choice === "light" || choice === "dark") {
            root.setAttribute("data-theme", choice);
        } else {
            root.removeAttribute("data-theme");
        }
    }

    /**
     * Applies a choice to the page and remembers it.
     * @param {string} choice
     */
    function choose(choice) {
        apply(choice);
        try {
            if (choice === "light" || choice === "dark") {
                localStorage.setItem(STORAGE_KEY, choice);
            } else {
                localStorage.removeItem(STORAGE_KEY);
            }
        } catch (_) {
            // The choice lasts for this page only when local storage is unavailable.
        }
    }

    /**
     * Sets up one theme control.
     * @param {HTMLElement} control
     */
    function setUp(control) {
        /** @type {HTMLButtonElement[]} */
        const buttons = Array.from(control.querySelectorAll("button[data-theme-choice]"));
        if (buttons.length === 0) return;

        function sync() {
            const choice = currentChoice();
            for (const button of buttons) {
                const checked = button.dataset.themeChoice === choice;
                button.setAttribute("aria-checked", checked ? "true" : "false");
                // Arrow keys move between the choices, so only the chosen one is a tab stop.
                button.tabIndex = checked ? 0 : -1;
            }
        }

        buttons.forEach((button, index) => {
            button.addEventListener("click", () => {
                choose(button.dataset.themeChoice ?? "auto");
                sync();
            });
            button.addEventListener("keydown", (event) => {
                let next = null;
                if (event.key === "ArrowRight" || event.key === "ArrowDown") {
                    next = buttons[(index + 1) % buttons.length];
                } else if (event.key === "ArrowLeft" || event.key === "ArrowUp") {
                    next = buttons[(index + buttons.length - 1) % buttons.length];
                }
                if (next) {
                    event.preventDefault();
                    next.focus();
                    next.click();
                }
            });
        });

        // Stay in step with other controls that set the theme.
        new MutationObserver(sync).observe(document.documentElement, {
            attributes: true,
            attributeFilter: ["data-theme"],
        });

        sync();
        control.hidden = false;
    }

    function init() {
        document.querySelectorAll("[data-verso-theme-toggle]").forEach((control) => {
            if (control instanceof HTMLElement) setUp(control);
        });
        // Follow a choice made in another tab of this site.
        window.addEventListener("storage", (event) => {
            if (event.key !== STORAGE_KEY && event.key !== null) return;
            const value = event.key === null ? null : event.newValue;
            apply(value === "light" || value === "dark" ? value : "auto");
        });
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", init);
    } else {
        init();
    }
})();
