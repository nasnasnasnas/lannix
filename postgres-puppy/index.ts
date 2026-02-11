import sdk from "@1password/sdk";
import { $ } from "bun";

const VAULT_ID = "q63632lctm4by3clskcul4gmf4";
const TAG = "MagicBox Postgres";

if (!process.env.OP_SERVICE_ACCOUNT_TOKEN) throw "No 1Password auth provided";

// Creates an authenticated client.
const client = await sdk.createClient({
	auth: process.env.OP_SERVICE_ACCOUNT_TOKEN,
	// Set the following to your own integration name and version.
	integrationName: "Postgres Puppy",
	integrationVersion: "v1.0.0",
});

function generateNewPassword() {
	return sdk.Secrets.generatePassword({
		type: "Random",
		parameters: {
			includeDigits: true,
			includeSymbols: true,
			length: 20,
		},
	}).password;
}

type PostgresDatabase = {
	name: string;
}

type Input = PostgresDatabase[];

if (!Bun.argv[2]) throw "No input parameter provided";
const input = JSON.parse(Bun.argv[2]) as Input;

const postgresItemOverviews = (await client.items.list(VAULT_ID))
	.filter(item => item.category === "Database" && item.tags.includes(TAG));
const postgresItems = await Promise.all(
	postgresItemOverviews.map(overview => client.items.get(overview.vaultId, overview.id))
);

for (let postgresDatabase of input) {
	let item = postgresItems.find(postgresItem => postgresItem.fields.find(field =>
		field.id === "database" && field.value === postgresDatabase.name));
	if (!item) {
		// create one
		item = await client.items.create({
			title: postgresDatabase.name + " Postgres",
			vaultId: VAULT_ID,
			category: sdk.ItemCategory.Database,
			tags: [TAG],
			fields: [
				{
					"id": "database_type",
					"title": "type",
					"fieldType": sdk.ItemFieldType.Text,
					"value": "postgresql",
				},
				{
					"id": "database",
					"title": "database",
					"fieldType": sdk.ItemFieldType.Text,
					"value": postgresDatabase.name,
				},
				{
					"id": "username",
					"title": "username",
					"fieldType": sdk.ItemFieldType.Text,
					"value": postgresDatabase.name,
				},
				{
					"id": "password",
					"title": "password",
					"fieldType": sdk.ItemFieldType.Concealed,
					"value": generateNewPassword(),
				},
			]
		});
	}

	let databasePassword = item.fields.find(field => field.id === "password")?.value;
	if (!databasePassword) {
		databasePassword = generateNewPassword();
		const updatedItem = {...item, fields: [...item.fields, {
				"id": "password",
				"title": "password",
				"fieldType": sdk.ItemFieldType.Concealed,
				"value": generateNewPassword(),
			} ]}
		await client.items.put(updatedItem);
	}

	console.log(`Creating database ${postgresDatabase.name} if it doesn't exist`)

	const sql = `CREATE USER IF NOT EXISTS ${postgresDatabase.name};
ALTER USER ${postgresDatabase.name} WITH PASSWORD '${databasePassword}';
SELECT 'CREATE DATABASE ${postgresDatabase.name} OWNER ${postgresDatabase.name}'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${postgresDatabase.name}')\\gexec`;

	await $`echo ${sql} | ${Bun.argv[3]} exec -i postgres psql -U postgres`
}

console.log("All Postgres databases updated")
