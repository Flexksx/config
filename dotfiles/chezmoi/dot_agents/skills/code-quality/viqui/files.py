import os

IGNORED_DIRECTORIES = {".git", ".venv", "node_modules", "__pycache__"}


def collect_files(path: str) -> list[str]:
    absolute = os.path.abspath(path)
    if os.path.isfile(absolute):
        return [absolute]
    files: list[str] = []
    for root, directories, names in os.walk(absolute):
        directories[:] = [
            name for name in directories if name not in IGNORED_DIRECTORIES
        ]
        for name in names:
            files.append(os.path.join(root, name))
    return files
