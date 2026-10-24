_root := justfile_directory()

@_default:
    @just --list --list-submodules

mod format '.just/format/Justfile'

ci:
    alejandra -c {{_root}}
    biome check {{_root}}
    stylua --check {{_root}}
    rumdl fmt --check {{_root}}
    find {{_root}} -type f -name '*.sh' -not -path '*/.git/*' -not -path '*/.direnv/*' -print0 | xargs -0 -r shfmt -d
    find {{_root}} -type f -name '*.toml' -not -path '*/.git/*' -not -path '*/.direnv/*' -not -path '*/.rumdl_cache/*' -print0 | xargs -0 -r taplo fmt --check
    yamlfmt -lint {{_root}}