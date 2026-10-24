const local = "^(?!node_modules)[^/]+\\.ts$|^(tools|ui)/";

module.exports = {
	forbidden: [
		{ name: "no-circular", severity: "error", from: {}, to: { circular: true } },
		{
			name: "leaves-import-nothing-local",
			severity: "error",
			from: { path: "^(agents|protocol|text|tool-proxy)\\.ts$" },
			to: { path: local },
		},
		{
			name: "run-is-domain-state",
			severity: "error",
			from: { path: "^run\\.ts$" },
			to: { path: local, pathNot: "^(agents|protocol)\\.ts$" },
		},
		{
			name: "child-session-builds-sessions-only",
			severity: "error",
			from: { path: "^child-session\\.ts$" },
			to: { path: local, pathNot: "^agents\\.ts$" },
		},
		{
			name: "manager-knows-no-tools-or-ui",
			severity: "error",
			from: { path: "^manager\\.ts$" },
			to: { path: "^(tools|ui)/|^(command|index)\\.ts$" },
		},
		{
			name: "tools-do-not-render",
			severity: "error",
			from: { path: "^tools/" },
			to: { path: "^ui/|^(command|index|child-session)\\.ts$" },
		},
		{
			name: "ui-only-renders",
			severity: "error",
			from: { path: "^ui/" },
			to: { path: "^tools/|^(manager|child-session|tool-proxy|command|index)\\.ts$" },
		},
		{
			name: "only-index-wires",
			severity: "error",
			from: { pathNot: "^index\\.ts$" },
			to: { path: "^index\\.ts$" },
		},
	],
	options: {
		tsPreCompilationDeps: true,
		doNotFollow: { path: "node_modules" },
		exclude: { path: "^/nix|node_modules" },
	},
};
