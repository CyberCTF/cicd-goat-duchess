import pytest

from duchess import moral_of, tidy


def test_tidy_collapses_whitespace():
    assert tidy("  be   what   you  seem ") == "be what you seem"


def test_moral_has_the_flourish():
    assert moral_of("birds of a feather flock together") == (
        "And the moral of that is — birds of a feather flock together."
    )


def test_empty_saying_is_refused():
    with pytest.raises(ValueError):
        moral_of("   ")
