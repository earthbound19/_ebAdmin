# DESCRIPTION
# Looks up all dependencies of a pip package and removes them and it.

# USAGE
#    python path-to/pip-superuninstall.py pip-package-name-to-super-uninstall

# Taken from: https://sqlpey.com/python/solved-how-to-uninstall-a-package-and-its-dependencies-in-python-using-pip/


# CODE
## pip-uninstall-with-dependencies.py
import sys
from pip._internal.commands.show import search_packages_info
from pip._internal.cli.main import main
from typing import List, Dict

if len(sys.argv) < 2:
    print(f"Usage: {sys.argv[0]} pkg1 [pkg2 ...]")
    exit(1)

def get_dependency_tree(packages: List[str], candidates: Dict[str, List[str]] = dict()) -> Dict[str, List[str]]:
    for package in packages:
        if not candidates.get(package):
            pkg_info = next(search_packages_info([package]))
            candidates[package] = pkg_info.required_by
            for dep in pkg_info.requires:
                get_dependency_tree([dep])
    return candidates

candidates = get_dependency_tree(sys.argv[1:])
for package in list(candidates):
    diff = set(candidates[package]).difference(list(candidates))
    if diff:
        print(f"Package {package} cannot be removed; it is required by {diff}")
        del candidates[package]

print("Uninstalling packages and dependencies:", *candidates)
for package in candidates:
    main(['uninstall', '-y', package])