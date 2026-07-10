import { RealtimeClient } from "@realtime-md/sdk";
import ollama from "ollama";

const token = process.env.REALTIME_TOKEN!;
const client = new RealtimeClient({
	baseUrl: "https://realtime.szpunar.cloud",
	token,
});
const vault = client.vault(process.env.REALTIME_VAULT_ID!);

// system prompt lives in vault for now
const systemPrompt = await vault.notes
	.read("Journal Sentiment Analysis Prompt.md")
	.then((note) => note.content);

// get today's date in America/Indiana/Indianapolis in ISO8601 format
const today = new Date().toLocaleDateString("en-US", {
	year: "numeric",
	month: "2-digit",
	day: "2-digit",
	timeZone: "America/Indiana/Indianapolis",
});

const todayISO = new Date(today).toISOString().split("T")[0];

// get all journal files
const journalFiles = (await vault.notes.list()).filter(
	(note) => note.path.startsWith("Journal/") && !note.path.endsWith("Guide.md"),
);
const journalFileNames = journalFiles
	.map((note) => note.path.split("/").pop()!.split(".")[0]!)
	.filter((name) => name !== todayISO); //filter out today's journal

// filter journals that already have sentiment analysis in sqlite
const database = vault.pluginDb("lavender-manager-next", "lavender");
const existingJournalNames = (
	await database.query("SELECT day FROM journal_sentiments")
).rows.map((row) => row[0]);
// sort chronologically (ISO date strings sort correctly) so each day's
// recent-context lookup sees the correctly-ordered prior days during a backfill
const newJournalEntries = journalFileNames
	.filter((journalName) => !existingJournalNames.includes(journalName))
	.sort();

// list member names
const memberNames = (await vault.notes.list())
	.filter((note) => note.path.startsWith("Members/"))
	.map((note) => note.path.split("/").pop()!.split(".")[0]!);

// Match a complete switch callout header and any existing body lines. Stop
// before an adjacent callout so unrelated blockquoted content is preserved.
const switchRegex =
	/^[ \t]*>[ \t]*\[!switch\][+-]?[ \t]+([0-9A-HJKMNP-TV-Z]{26})[ \t]*\r?(?=\n|$)(?:\n(?![ \t]*>[ \t]*\[!)[ \t]*>[^\r\n]*\r?)*/gim;
// Remove only the generated summary callout. An adjacent callout starts a new
// block even when no blank line separates it from the summary.
const lavenderSummaryRegex =
	/^[ \t]*>[ \t]*\[!lavender-summary\][^\r\n]*\r?(?=\n|$)(?:\n(?![ \t]*>[ \t]*\[!)[ \t]*>[^\r\n]*\r?)*(?:\n|$)/gim;

// do sentiment analysis on each
for (const journalEntryName of newJournalEntries) {
	const [year, month] = journalEntryName.split("-");
	console.log(`Journal/${year}/${month}/${journalEntryName}.md`);

	const journalEntry = await vault.notes.read(
		`Journal/${year}/${month}/${journalEntryName}.md`,
	);
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
			$schema: "https://json-schema.org/draft/2020-12/schema",
			type: "object",
			required: ["members"],
			properties: {
				note: {
					type: "string",
					description:
						"A optional short (~150-200 characters max) description of the day in general.",
				},
				memo: {
					type: "string",
					description:
						"Optional carry-forward facts about the SYSTEM as a whole (not tied to any single member) that will help interpret FUTURE journal entries (e.g. a shared upcoming event, a move, a household-wide situation, a group decision). Not a restatement of the day's mood or of the note. Omit unless there's a concrete fact worth remembering across days.",
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
								enum: memberNames,
							},
							score: {
								description:
									"Sentiment analysis score for this member. Neutral is 0.0, negative is -1.0, and positive is 1.0.",
								type: "number",
								minimum: -1,
								maximum: 1,
							},
							note: {
								type: "string",
								description:
									"An optional short (~100-150 characters max) note of the day for this member.",
							},
							memo: {
								type: "string",
								description:
									"Optional carry-forward facts about this member that will help interpret their FUTURE journal entries (e.g. ongoing situations, upcoming events like 'exams this week' or 'started a new job'). Not a restatement of mood or a score justification. Omit unless there's a concrete fact worth remembering across days.",
							},
						},
					},
				},
			},
		},
		think: true,
		stream: false,
	});

	console.log(ollamaResponse);
	const sentimentAnalysis = JSON.parse(ollamaResponse.response);
	const statements = [
		{
			sql: "INSERT INTO journal_sentiments (day, note, memo) VALUES (?, ?, ?)",
			params: [
				journalEntryName,
				sentimentAnalysis.note?.trim() ? sentimentAnalysis.note : null,
				sentimentAnalysis.memo?.trim() ? sentimentAnalysis.memo : null,
			],
		},
	];
	for (const member of sentimentAnalysis.members) {
		const { name, score, note, memo } = member;
		if (!memberNames.includes(name)) {
			console.warn(`Member ${name} not found in Members folder. Skipping.`);
			continue;
		}
		statements.push({
			sql: "INSERT INTO journal_sentiment_members (day, member, score, note, memo) VALUES (?, ?, ?, ?, ?)",
			params: [
				journalEntryName,
				name,
				score,
				note?.trim() ? note : null,
				memo?.trim() ? memo : null,
			],
		});
	}
	await database.execute(statements);

	console.log(
		`Sentiment analysis complete for ${journalEntryName} in ${ollamaResponse.total_duration / 1_000_000_000} seconds (${ollamaResponse.eval_count / ollamaResponse.eval_duration / 1_000_000_000} tok/s): <input>${processedBody}</input> <thinking>${ollamaResponse.thinking}</thinking> ${ollamaResponse.response}`,
	);
}

// Build a compact digest of carry-forward facts (memos) from the prior few
// days, so the model has continuity without anchoring today's score to past
// scores. Facts only — scores are deliberately NOT fed back.
async function buildRecentContext(
	beforeDay: string,
	windowDays = 7,
	maxDays = 4,
): Promise<string> {
	// cutoff so a long gap between entries doesn't drag in stale context
	const cutoff = new Date(beforeDay);
	cutoff.setDate(cutoff.getDate() - windowDays);
	const cutoffISO = cutoff.toISOString().split("T")[0]!;

	const memberRows = (
		await database.query(
			"SELECT day, member, memo FROM journal_sentiment_members WHERE day < ? AND day >= ? AND memo IS NOT NULL ORDER BY day ASC LIMIT ?",
			{ params: [beforeDay, cutoffISO, maxDays * 6] },
		)
	).rows as [string, string, string][];
	// system-wide memos live on journal_sentiments, one per day
	const systemRows = (
		await database.query(
			"SELECT day, memo FROM journal_sentiments WHERE day < ? AND day >= ? AND memo IS NOT NULL ORDER BY day ASC LIMIT ?",
			{ params: [beforeDay, cutoffISO, maxDays] },
		)
	).rows as [string, string][];
	if (memberRows.length === 0 && systemRows.length === 0) return "";

	// keep only the most recent `maxDays` distinct days across both sources, oldest→newest
	const days = [
		...new Set([
			...systemRows.map(([day]) => day),
			...memberRows.map(([day]) => day),
		]),
	]
		.sort()
		.slice(-maxDays);
	const kept = new Set(days);
	const systemByDay = new Map(systemRows.filter(([day]) => kept.has(day)));
	const byDay = new Map<string, string[]>();
	for (const [day, member, memo] of memberRows) {
		if (!kept.has(day)) continue;
		(byDay.get(day) ?? byDay.set(day, []).get(day)!).push(`${member}: ${memo}`);
	}

	const lines = days.map((day) => {
		const parts = [
			...(systemByDay.has(day) ? [`system: ${systemByDay.get(day)}`] : []),
			...(byDay.get(day) ?? []),
		];
		return `${day}  ${parts.join("   ")}`;
	});
	return [
		"Recent context (facts to keep in mind — score today independently, do not copy):",
		...lines,
	].join("\n");
}

async function preprocessJournalBody(body: string) {
	body = body.replace(lavenderSummaryRegex, "");

	// String.replace runs its callback synchronously, so gather the unique
	// normalized switch ids first, resolve them asynchronously, then replace
	// every matching callout using the map.
	const switchIds = [
		...new Set(
			[...body.matchAll(switchRegex)]
				.map(([, switchId]) => switchId?.toUpperCase())
				.filter((id): id is string => id !== undefined),
		),
	];

	const replacements = new Map<string, string>();
	await Promise.all(
		switchIds.map(async (switchId) => {
			try {
				const row = (
					await database.query(
						"SELECT ts, notes FROM switches WHERE id = ? LIMIT 1",
						{ params: [switchId] },
					)
				).rows[0];
				if (!row) {
					console.warn(
						`Switch ${switchId} not found in switches table. Leaving callout as-is.`,
					);
					return;
				}

				const [switchTs, notes] = row;
				const memberRows = (
					await database.query(
						"SELECT member, role FROM switch_members WHERE switch_id = ? ORDER BY COALESCE(position, 0) ASC, member ASC",
						{ params: [switchId] },
					)
				).rows;
				const replacementLines = [
					`> [!switch] ${switchId}`,
					...(typeof switchTs === "string" && switchTs.trim()
						? [`> Switched at: ${switchTs}`]
						: []),
				];

				if (typeof notes === "string" && notes.trim()) {
					const [firstLine, ...continuationLines] = notes.trim().split(/\r?\n/);
					replacementLines.push(
						`> Notes: ${firstLine}`,
						...continuationLines.map((line) => `> ${line}`),
					);
				}

				replacementLines.push(
					"> Members:",
					...memberRows.map(([member, role]) => `> ${member}: ${role}`),
				);
				replacements.set(switchId, replacementLines.join("\n"));
			} catch (error) {
				console.warn(
					`Failed to resolve switch ${switchId}. Leaving callout as-is.`,
					error,
				);
			}
		}),
	);

	return body.replace(
		switchRegex,
		(match, switchId: string) =>
			replacements.get(switchId.toUpperCase()) ?? match,
	);
}
