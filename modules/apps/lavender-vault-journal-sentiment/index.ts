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
const newJournalEntries = journalFileNames.filter(journalName => !existingJournalNames.includes(journalName));

// do sentiment analysis on each
for (const journalEntryName of newJournalEntries) {
	const [year, month] = journalEntryName.split("-");
	console.log(`Journal/${year}/${month}/${journalEntryName}.md`);
	
	const journalEntry = await vault.notes.read(`Journal/${year}/${month}/${journalEntryName}.md`);
	const body = journalEntry.content;
	const processedBody = await preprocessJournalBody(body);
	
	const ollamaResponse = await ollama.generate({
		model: "gemma4:e4b-it-qat",
		prompt: processedBody,
		system: systemPrompt,
		format: {
			"$schema": "https://json-schema.org/draft/2020-12/schema",
			type: "object",
			required: ["members"],
			properties: {
				note: {
					type: "string",
					description: "A short (~200-300 characters) description of the day in general."
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
								description: "An optional short (~150-200 characters) note of the day for this member."
							}
						},
					}
				}
			}
		},
		think: true,
		stream: false,
	})

	const sentimentAnalysis = JSON.parse(ollamaResponse.response);
	const statements = [{ sql: "INSERT INTO journal_sentiments (day, note) VALUES (?, ?)", params: [journalEntryName, sentimentAnalysis.note] }];
	for (const member of sentimentAnalysis.members) {
		const { name, score, note } = member;
		statements.push({ sql: "INSERT INTO journal_sentiment_members (day, member, score, note) VALUES (?, ?, ?, ?)", params: [journalEntryName, name, score, note] });
	}
	await database.execute(statements);
	console.log(ollamaResponse);
	
	console.log(`Sentiment analysis complete for ${journalEntryName} in ${ollamaResponse.total_duration / 1_000_000_000}: <thinking>${ollamaResponse.thinking}</thinking> ${ollamaResponse.response}`);
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
