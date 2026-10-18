"""Core helpers.

The Duchess is fond of finding a moral in everything; these helpers keep that tidy.
"""

from __future__ import annotations


def tidy(text: str) -> str:
    """Collapse runs of whitespace and trim the ends."""
    return " ".join(text.split())


def moral_of(saying: str) -> str:
    """Return the Duchess's moral for a saying: tidied, with her flourish."""
    saying = tidy(saying)
    if not saying:
        raise ValueError("every saying has a moral, but not an empty one")
    return f"And the moral of that is — {saying}."
