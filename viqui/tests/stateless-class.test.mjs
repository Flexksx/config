import assert from "node:assert/strict";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";
import { scanRules } from "../core/registry.mjs";

const rules = join(dirname(fileURLToPath(import.meta.url)), "../rules");

test("reports stateless Python classes and TypeScript members without instance state", (t) => {
  const root = mkdtempSync(join(tmpdir(), "stateless-class-"));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const python = join(root, "layers.py");
  const typescript = join(root, "layers.ts");
  writeFileSync(
    python,
    `class UserService:
    def get(self, identifier):
        return self.lookup(identifier)
    def lookup(self, identifier):
        return repository.get(identifier)

class UserRepository:
    def get(self, identifier):
        return query(identifier)

class ConfiguredRepository:
    def get(self, identifier):
        return self.database.get(identifier)

class Child(Base):
    def get(self):
        return query()

@framework
class Controller:
    def get(self):
        return query()

class Record:
    name: str
`,
  );
  writeFileSync(
    typescript,
    `class UserService {
  get(id: string) { return this.lookup(id); }
  lookup(id: string) { return repository.get(id); }
}
class UserRepository { get(id: string) { return query(id); } }
class ConfiguredRepository {
  constructor(private database: Database) {}
  get(id: string) { return this.database.get(id); }
}
class Child extends Base { get() { return query(); } }
class Adapter implements Port { get() { return query(); } }
class Record { name: string; }
`,
  );
  const findings = scanRules(rules, [python, typescript]).filter(
    (finding) => finding.rule === "no-stateless-class",
  );
  assert.deepEqual(
    findings.map(({ file, line }) => [file, line]),
    [
      [python, 1],
      [python, 7],
      [typescript, 3],
      [typescript, 5],
      [typescript, 10],
      [typescript, 11],
    ],
  );
});
