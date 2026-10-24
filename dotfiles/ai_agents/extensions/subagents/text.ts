const RESULT_LIMIT = 50_000;

export function truncate(text: string): string {
	return text.length > RESULT_LIMIT ? `${text.slice(0, RESULT_LIMIT)}\n… truncated. The full transcript is in /subagents.` : text;
}

export function clip(text: string, max = 100): string {
	const line = text.replace(/\s+/g, " ").trim();
	return line.length > max ? `${line.slice(0, max - 1)}…` : line;
}

export function errorText(error: unknown): string {
	return error instanceof Error ? error.message : String(error);
}
