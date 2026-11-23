from playwright.sync_api import Page, expect

LIGHT_BACKGROUND = "rgb(255, 255, 255)"
DARK_BACKGROUND = "rgb(22, 24, 29)"


def page_background(page: Page) -> str:
    return page.evaluate("getComputedStyle(document.documentElement).backgroundColor")


def theme_attribute(page: Page):
    return page.evaluate("document.documentElement.getAttribute('data-theme')")


def stored_theme(page: Page):
    return page.evaluate("localStorage.getItem('verso-theme')")


def open_site(page: Page, server: str, scheme: str) -> None:
    page.set_viewport_size({"width": 1200, "height": 800})
    page.emulate_media(color_scheme=scheme)
    page.goto(f"{server}/")
    page.wait_for_load_state("networkidle")


class TestTheme:
    def test_follows_system_color_scheme_by_default(self, server: str, page: Page):
        """Without a stored choice, the page follows the system and "Auto" is chosen."""
        open_site(page, server, "dark")
        control = page.get_by_role("radiogroup", name="Color theme")
        expect(control).to_be_visible()
        expect(control.get_by_role("radio", name="Auto")).to_have_attribute("aria-checked", "true")
        assert theme_attribute(page) is None
        assert page_background(page) == DARK_BACKGROUND

        page.emulate_media(color_scheme="light")
        assert page_background(page) == LIGHT_BACKGROUND

    def test_explicit_choice_overrides_system_and_persists(self, server: str, page: Page):
        """Choosing a theme overrides the system scheme, is stored, and survives a reload."""
        open_site(page, server, "light")
        control = page.get_by_role("radiogroup", name="Color theme")
        control.get_by_role("radio", name="Dark").click()
        assert theme_attribute(page) == "dark"
        assert stored_theme(page) == "dark"
        assert page_background(page) == DARK_BACKGROUND

        page.reload()
        page.wait_for_load_state("networkidle")
        assert theme_attribute(page) == "dark"
        assert page_background(page) == DARK_BACKGROUND
        expect(control.get_by_role("radio", name="Dark")).to_have_attribute("aria-checked", "true")

        # An explicit light choice wins over a dark system scheme.
        page.emulate_media(color_scheme="dark")
        control.get_by_role("radio", name="Light").click()
        assert theme_attribute(page) == "light"
        assert stored_theme(page) == "light"
        assert page_background(page) == LIGHT_BACKGROUND

    def test_auto_clears_the_stored_choice(self, server: str, page: Page):
        """Going back to "Auto" removes the attribute and the stored choice."""
        open_site(page, server, "dark")
        control = page.get_by_role("radiogroup", name="Color theme")
        control.get_by_role("radio", name="Light").click()
        assert page_background(page) == LIGHT_BACKGROUND

        control.get_by_role("radio", name="Auto").click()
        assert theme_attribute(page) is None
        assert stored_theme(page) is None
        assert page_background(page) == DARK_BACKGROUND

    def test_stored_choice_applies_before_first_paint(self, server: str, page: Page):
        """The head script applies a stored choice before the deferred scripts run."""
        open_site(page, server, "light")
        page.evaluate("localStorage.setItem('verso-theme', 'dark')")
        page.goto(f"{server}/", wait_until="commit")
        # The attribute is already set when the document's body is first parsed.
        page.wait_for_selector("body", state="attached")
        assert theme_attribute(page) == "dark"

    def test_follows_other_scripts_that_set_the_theme(self, server: str, page: Page):
        """The control reflects a theme that another script sets on the root element."""
        open_site(page, server, "light")
        page.evaluate("document.documentElement.setAttribute('data-theme', 'dark')")
        control = page.get_by_role("radiogroup", name="Color theme")
        expect(control.get_by_role("radio", name="Dark")).to_have_attribute("aria-checked", "true")
