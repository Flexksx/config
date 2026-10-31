module.exports = {
  forbidden: [
    {
      name: "no-cross-rule-imports",
      severity: "error",
      from: { path: "^viqui/rules/([^/]+)/" },
      to: {
        path: "^viqui/rules/",
        pathNot: "^viqui/rules/$1/",
      },
    },
  ],
  options: { doNotFollow: { path: "node_modules" } },
};
