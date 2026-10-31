const { createRequire } = require("node:module");

exports.process = (source, filename) => {
  const typescript = createRequire(filename)("typescript");
  return {
    code: typescript.transpileModule(source, {
      compilerOptions: { module: typescript.ModuleKind.ESNext },
      fileName: filename,
    }).outputText,
  };
};
