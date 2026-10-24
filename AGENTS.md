# AI Agents Instructions

## Markdown Style

Each sentence in a markdown file must start on a new line.

This keeps diffs clean and makes sentence-level edits easier to review.

Do not wrap multiple sentences onto the same line.

It is important to avoid redundant information,
repeating the same thing in other words.

Code examples should be brief and illustrate functionality

### Code examples

Blocks with code examples should contain the example and the
counter-example as a piece of the same code block.

Separate them with comments rather than adding a new code block.

## Rebuilding

Never rebuild the system `nix` configuration.

You should use `nix build` to verify that your changes
are correct before applying them.

Do that only for nix-related changes, not for other configuration changes.
