"""Tiny health endpoint."""


def health() -> dict[str, str]:
    return {"status": "ok"}


if __name__ == "__main__":
    print(health())
