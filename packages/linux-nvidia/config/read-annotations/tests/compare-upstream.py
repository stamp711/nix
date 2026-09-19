"""Compare the Nix reader with the annotation parser shipped in the kernel."""

import json
import sys
from pathlib import Path

sys.dont_write_bytecode = True
source, annotations_path, nix_configs_path = sys.argv[1:]
sys.path.insert(0, str(Path(source) / "debian/scripts/misc"))

from kconfig.annotations import Annotation  # noqa: E402

annotation = Annotation(str(Path(source) / annotations_path))
for arch, actual in json.loads(Path(nix_configs_path).read_text()).items():
    upstream = annotation.search_config(arch=arch, flavour="nvidia")
    upstream = {name: value for name, value in upstream.items() if value != "-"}
    differences = {
        name: {"upstream": upstream.get(name), "nix": actual.get(name)}
        for name in upstream.keys() | actual.keys()
        if upstream.get(name) != actual.get(name)
    }
    if differences:
        raise SystemExit(
            f"{arch}: " + json.dumps(differences, indent=2, sort_keys=True)
        )
    print(f"{arch}: all {len(upstream)} NVIDIA settings match the Nix reader")
