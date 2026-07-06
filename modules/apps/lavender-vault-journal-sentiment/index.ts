import { RealtimeClient } from "@realtime-md/sdk";
import ollama from "ollama";

const token = process.env.REALTIME_TOKEN!;
const client = new RealtimeClient({ baseUrl: "https://realtime.szpunar.cloud", token });
const vault = client.vault(process.env.REALTIME_VAULT_ID!);

// system prompt lives in vault for now
const systemPrompt = await vault.notes.read("Journal Sentiment Analysis Prompt.md").then(note => note.content);


// get today's date in America/Indiana/Indianapolis in ISO8601 format
const today = new Date().toLocaleDateString('en-US', {
	year: 'numeric',
	month: '2-digit',
	day: '2-digit',
	timeZone: 'America/Indiana/Indianapolis'
});

const todayISO = new Date(today).toISOString().split("T")[0];

// get all journal files
const journalFiles = (await vault.notes.list()).filter(note => note.path.startsWith("Journal/") && !note.path.endsWith("Guide.md"));
const journalFileNames = journalFiles.map(note => note.path.split("/").pop()!.split(".")[0]!).filter(name => name !== todayISO); //filter out today's journal

// filter journals that already have sentiment analysis in sqlite
const database = vault.pluginDb("lavender-manager-next", "lavender");
const existingJournalNames = (await database.query("SELECT day FROM journal_sentiments")).rows.map(row => row[0]);
// sort chronologically (ISO date strings sort correctly) so each day's
// recent-context lookup sees the correctly-ordered prior days during a backfill
const newJournalEntries = journalFileNames.filter(journalName => !existingJournalNames.includes(journalName)).sort();

// list member names
const memberNames = (await vault.notes.list()).filter(note => note.path.startsWith("Members/")).map(note => note.path.split("/").pop()!.split(".")[0]!);

// do sentiment analysis on each
for (const journalEntryName of newJournalEntries) {
	const [year, month] = journalEntryName.split("-");
	console.log(`Journal/${year}/${month}/${journalEntryName}.md`);
	
	const journalEntry = await vault.notes.read(`Journal/${year}/${month}/${journalEntryName}.md`);
	const body = journalEntry.content;
	const processedBody = await preprocessJournalBody(body);
	const recentContext = await buildRecentContext(journalEntryName);
	const prompt = recentContext
		? `${recentContext}\n\n---\n\nToday's entry (${journalEntryName}):\n${processedBody}`
		: processedBody;

	const ollamaResponse = await ollama.generate({
		model: "gemma4:e4b",
		prompt,
		system: systemPrompt,
		format: {
			"$schema": "https://json-schema.org/draft/2020-12/schema",
			type: "object",
			required: ["members"],
			properties: {
				note: {
					type: "string",
					description: "A optional short (~150-200 characters max) description of the day in general."
				},
				members: {
					type: "array",
					description: "One for each member who wrote in the journal this day.",
					items: {
						type: "object",
						required: ["name", "score"],
						properties: {
							name: {
								type: "string",
							},
							score: {
								description: "Sentiment analysis score for this member. Neutral is 0.0, negative is -1.0, and positive is 1.0.",
								type: "number",
								minimum: -1,
								maximum: 1,
							},
							note: {
								type: "string",
								description: "An optional short (~100-150 characters max) note of the day for this member."
							},
							memo: {
								type: "string",
								description: "Optional carry-forward facts about this member that will help interpret their FUTURE journal entries (e.g. ongoing situations, upcoming events like 'exams this week' or 'started a new job'). Not a restatement of mood or a score justification. Omit unless there's a concrete fact worth remembering across days."
							}
						},
					}
				}
			}
		},
		think: true,
		stream: false,
	})

	console.log(ollamaResponse);
	const sentimentAnalysis = JSON.parse(ollamaResponse.response);
	const statements = [{ sql: "INSERT INTO journal_sentiments (day, note) VALUES (?, ?)", params: [journalEntryName, sentimentAnalysis.note?.trim() !== "" ? sentimentAnalysis.note : null] }];
	for (const member of sentimentAnalysis.members) {
		const { name, score, note, memo } = member;
		if (!memberNames.includes(name)) {
			console.warn(`Member ${name} not found in Members folder. Skipping.`);
			continue;
		}
		statements.push({ sql: "INSERT INTO journal_sentiment_members (day, member, score, note, memo) VALUES (?, ?, ?, ?, ?)", params: [journalEntryName, name, score, note?.trim() ? note : null, memo?.trim() ? memo : null] });
	}
	await database.execute(statements);
	
	console.log(`Sentiment analysis complete for ${journalEntryName} in ${ollamaResponse.total_duration / 1_000_000_000} seconds (${ollamaResponse.eval_count / ollamaResponse.eval_duration / 1_000_000_000} tok/s): <input>${processedBody}</input> <thinking>${ollamaResponse.thinking}</thinking> ${ollamaResponse.response}`);
}

// Build a compact digest of carry-forward facts (memos) from the prior few
// days, so the model has continuity without anchoring today's score to past
// scores. Facts only — scores are deliberately NOT fed back.
async function buildRecentContext(beforeDay: string, windowDays = 7, maxDays = 4): Promise<string> {
	// cutoff so a long gap between entries doesn't drag in stale context
	const cutoff = new Date(beforeDay);
	cutoff.setDate(cutoff.getDate() - windowDays);
	const cutoffISO = cutoff.toISOString().split("T")[0]!;

	const rows = (await database.query(
		"SELECT day, member, memo FROM journal_sentiment_members WHERE day < ? AND day >= ? AND memo IS NOT NULL ORDER BY day ASC LIMIT ?",
		{ params: [beforeDay, cutoffISO, maxDays * 6] }
	)).rows as [string, string, string][];
	if (rows.length === 0) return "";

	// keep only the most recent `maxDays` distinct days, then render oldest→newest
	const days = [...new Set(rows.map(([day]) => day))].slice(-maxDays);
	const kept = new Set(days);
	const byDay = new Map<string, string[]>();
	for (const [day, member, memo] of rows) {
		if (!kept.has(day)) continue;
		(byDay.get(day) ?? byDay.set(day, []).get(day)!).push(`${member}: ${memo}`);
	}

	const lines = days.map(day => `${day}  ${(byDay.get(day) ?? []).join("   ")}`);
	return [
		"Recent context (facts to keep in mind — score today independently, do not copy):",
		...lines,
	].join("\n");
}

const switchRegex = /> \[!switch] ([A-Z0-9]{26})/gm;
async function preprocessJournalBody(body: string) {
	// String.replace runs its callback synchronously, so gather the unique
	// switch ids first, resolve them asynchronously, then replace using the map.
	const switchIds = [...new Set([...body.matchAll(switchRegex)].map(([, switchId]) => switchId).filter((id): id is string => id !== undefined))];

	const replacements = new Map<string, string>();
	await Promise.all(switchIds.map(async (switchId) => {
		const row = (await database.query("SELECT ts, notes, created_at FROM switches WHERE id = ? LIMIT 1", { params: [switchId] })).rows[0];
		if (!row) return;
		const [switchTs, notes, created_at] = row;
		const memberDetails = (await database.query("SELECT member, role FROM switch_members WHERE switch_id = ? LIMIT 1", { params: [switchId] })).rows.map(([member, role]) => `${member}: ${role}`).join('\n')
		replacements.set(switchId, `> [!switch] ${switchId}
> Created at: ${created_at}
> Notes: ${notes}
> Members:
${memberDetails}`);
	}));

	return body.replace(switchRegex, (match, switchId) => replacements.get(switchId) ?? match);
}
