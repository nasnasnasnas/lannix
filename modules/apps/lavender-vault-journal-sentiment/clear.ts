import { RealtimeClient } from "@realtime-md/sdk";

const token = process.env.REALTIME_TOKEN!;
const client = new RealtimeClient({ baseUrl: "https://realtime.szpunar.cloud", token });
const vault = client.vault(process.env.REALTIME_VAULT_ID!);

const database = vault.pluginDb("lavender-manager-next", "lavender");

await database.execute([
	{ sql: "DELETE FROM journal_sentiment_members" },
	{ sql: "DELETE FROM journal_sentiments" },
]);

console.log("Cleared all journal sentiment data.");
