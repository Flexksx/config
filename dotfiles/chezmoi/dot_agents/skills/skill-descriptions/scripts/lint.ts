#!/usr/bin/env bun
import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";

const MAX_CHARS = 1024;
const SOFT_CHARS = 600;

type Skill = { name: string; description: string };

const frontmatter = (raw: string): string => raw.match(/^---\r?\n([\s\S]*?)\r?\n---/)?.[1] ?? "";

const isBlockScalar = (value: string): boolean => value.startsWith(">") || value.startsWith("|") || value === "";

const descriptionOf = (raw: string): string => {
	const lines = frontmatter(raw).split("\n");
	const start = lines.findIndex((line) => /^description:/.test(line));
	if (start < 0) {
		return "";
	}
	const first = lines[start].replace(/^description:/, "").trim();
	if (!isBlockScalar(first)) {
		const inline = [first];
		for (const line of lines.slice(start + 1)) {
			if (/^\S/.test(line) && line.trim() !== "") {
				break;
			}
			inline.push(line.trim());
		}
		return inline.join(" ").replace(/\s+/g, " ").trim().replace(/^["']|["']$/g, "");
	}
	const body: string[] = [];
	for (const line of lines.slice(start + 1)) {
		if (/^\S/.test(line) && line.trim() !== "") {
			break;
		}
		body.push(line.trim());
	}
	return body.join(" ").replace(/\s+/g, " ").trim();
};

const findSkills = (root: string): Skill[] => {
	const found: Skill[] = [];
	for (const entry of readdirSync(root, { withFileTypes: true })) {
		const path = join(root, entry.name);
		if (!entry.isDirectory() && !entry.isSymbolicLink()) {
			continue;
		}
		if (!existsSync(path) || !statSync(path).isDirectory()) {
			continue;
		}
		const file = join(path, "SKILL.md");
		if (existsSync(file)) {
			found.push({ name: entry.name, description: descriptionOf(readFileSync(file, "utf8")) });
		}
	}
	return found;
};

const BOUNDARY = /\b(?:Do not use|Not for)\b/i;

const claimedPart = (description: string): string => description.split(BOUNDARY)[0] ?? description;

const signalsOf = (description: string): string[] =>
	[...new Set([...claimedPart(description).matchAll(/`([^`]+)`/g)].map((match) => match[1].toLowerCase()))];

const check = (skill: Skill, claims: Map<string, string[]>): string[] => {
	const problems: string[] = [];
	const description = skill.description;
	if (description === "") {
		return ["no description"];
	}
	if (description.length > MAX_CHARS) {
		problems.push(`${description.length} chars, limit ${MAX_CHARS}`);
	} else if (description.length > SOFT_CHARS) {
		problems.push(`${description.length} chars, preferred under ${SOFT_CHARS}`);
	}
	if (!/\buse\b/i.test(description)) {
		problems.push('no imperative "Use when ..." sentence');
	}
	if (signalsOf(description).length === 0) {
		problems.push("no signal: put a file name, extension, command or symbol in backticks");
	}
	if (!BOUNDARY.test(description)) {
		problems.push('no boundary: add "Do not use for X; use `other-skill` instead"');
	}
	for (const signal of signalsOf(description)) {
		const others = (claims.get(signal) ?? []).filter((owner) => owner !== skill.name);
		if (others.length > 0) {
			problems.push(`signal "${signal}" is also claimed by ${others.join(", ")}`);
		}
	}
	return problems;
};

const root = process.argv[2];
if (!root || !existsSync(root)) {
	console.error("usage: bun lint.ts <skills-directory>");
	process.exit(2);
}

const skills = findSkills(root);
if (skills.length === 0) {
	console.error(`no SKILL.md found under ${root}`);
	process.exit(2);
}

const claims = new Map<string, string[]>();
for (const skill of skills) {
	for (const signal of signalsOf(skill.description)) {
		claims.set(signal, [...(claims.get(signal) ?? []), skill.name]);
	}
}

let failed = 0;
for (const skill of skills) {
	const problems = check(skill, claims);
	if (problems.length === 0) {
		console.log(`ok    ${skill.name}  ${skill.description.length} chars`);
		continue;
	}
	failed += 1;
	console.log(`FAIL  ${skill.name}`);
	for (const problem of problems) {
		console.log(`        ${problem}`);
	}
}

console.log(`\n${skills.length - failed}/${skills.length} pass`);
process.exit(failed === 0 ? 0 : 1);
