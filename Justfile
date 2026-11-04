_root := justfile_directory()

@_default:
    @just --list --list-submodules

mod format '.just/format/Justfile'

ci:
    alejandra -c {{_root}}
    bun x biome check {{_root}}
    stylua --check {{_root}}
    rumdl fmt --check {{_root}}
    find {{_root}} -type f -name '*.sh' -not -path '*/.git/*' -not -path '*/.direnv/*' -not -path '*/.cache/*' -not -path '*/node_modules/*' -print0 | xargs -0 -r shfmt -d
    find {{_root}} -type f -name '*.toml' -not -path '*/.git/*' -not -path '*/.direnv/*' -not -path '*/.rumdl_cache/*' -not -path '*/.cache/*' -not -path '*/node_modules/*' -print0 | xargs -0 -r taplo fmt --check
    yamlfmt -gitignore_excludes -lint .