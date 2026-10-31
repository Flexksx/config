import { ExtensionRunner, type ToolRenderers } from "@earendil-works/pi-coding-agent";

const RUNNER_SLOT = Symbol.for("subagents.mainExtensionRunner");
const PATCHED = Symbol.for("subagents.resolveToolRenderers.patched");
type Slots = Record<symbol, unknown>;

export function installRendererCapture(): void {
	const proto = ExtensionRunner.prototype as unknown as Slots & Pick<ExtensionRunner, "resolveToolRenderers">;
	if (proto[PATCHED]) return;
	const original = proto.resolveToolRenderers;
	proto.resolveToolRenderers = function (this: ExtensionRunner, ...args) {
		(globalThis as Slots)[RUNNER_SLOT] = this;
		return original.apply(this, args);
	};
	Object.defineProperty(proto, PATCHED, { value: true });
}

export function rowRenderers(name: string, base: ToolRenderers | undefined): ToolRenderers | undefined {
	const runner = (globalThis as Slots)[RUNNER_SLOT] as ExtensionRunner | undefined;
	try {
		return runner?.resolveToolRenderers(name, () => base) ?? base;
	} catch {
		return base;
	}
}
