// @ts-nocheck
// This file is prepended with `const DNS_CONFIG = {...};` by the Nix script.
declare const DNS_CONFIG: DnsConfig;

interface WantedRecord {
  name: string;
  type: string;
  content: string;
  proxied: boolean;
  ttl: number;
}

interface DnsConfig {
  domains: Record<string, WantedRecord[]>;
}

interface CloudflareRecord {
  id: string;
  name: string;
  type: string;
  content: string;
}

async function cfApiFetch(path: string, token: string): Promise<any> {
  const response = await fetch(`https://api.cloudflare.com/client/v4${path}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!response.ok) {
    throw new Error(
      `Cloudflare API error: ${response.status} ${response.statusText}`,
    );
  }
  return response.json();
}

async function fetchZoneId(domain: string, token: string): Promise<string> {
  const data = await cfApiFetch(`/zones?name=${encodeURIComponent(domain)}`, token);
  if (!data.result?.length) {
    throw new Error(`Zone not found for domain: ${domain}`);
  }
  return data.result[0].id;
}

async function fetchDnsRecords(
  zoneId: string,
  token: string,
): Promise<CloudflareRecord[]> {
  const allRecords: CloudflareRecord[] = [];
  let page = 1;

  while (true) {
    const data = await cfApiFetch(
      `/zones/${zoneId}/dns_records?page=${page}&per_page=100`,
      token,
    );

    allRecords.push(...data.result);
    if (data.result_info.page >= data.result_info.total_pages) break;
    page++;
  }

  return allRecords;
}

function findRecordId(
  existing: CloudflareRecord[],
  name: string,
  type: string,
  domain: string,
): string | undefined {
  const fullName = name.includes(".") ? name : `${name}.${domain}`;
  return existing.find((r) => r.name === fullName && r.type === type)?.id;
}

function buildResource(
  record: WantedRecord,
  zoneVarRef: string,
  zoneId: string,
  existingId?: string,
): Record<string, unknown> {
  const resource: Record<string, unknown> = {
    type: "cloudflare:Record",
    properties: {
      zoneId: zoneVarRef,
      name: record.name,
      type: record.type,
      content: record.content,
      ttl: record.ttl,
      proxied: record.proxied,
    },
  };

  const enableImport = process.env.ENABLE_IMPORT === "1";
  if (enableImport && existingId) {
    resource.options = { import: `${zoneId}/${existingId}` };
  }

  return resource;
}

function domainToVarName(domain: string): string {
  return `zoneId_${domain.replace(/\./g, "_")}`;
}

async function main() {
  const token = process.env.CLOUDFLARE_API_TOKEN;
  if (!token) {
    console.error(
      "Error: CLOUDFLARE_API_TOKEN environment variable is required",
    );
    process.exit(1);
  }

  const config = (DNS_CONFIG as unknown) as DnsConfig;
  const domains = Object.keys(config.domains);

  const variables: Record<string, string> = {};
  const resources: Record<string, Record<string, unknown>> = {};

  for (const domain of domains) {
    const zoneId = await fetchZoneId(domain, token);
    const varName = domainToVarName(domain);
    variables[varName] = zoneId;

    const existingRecords = await fetchDnsRecords(zoneId, token);
    const zoneVarRef = `\${${varName}}`;

    for (const record of config.domains[domain]) {
      const existingId = findRecordId(
        existingRecords,
        record.name,
        record.type,
        domain,
      );
      const resourceKey = `${record.name}-${domain.replace(/\./g, "-")}`;
      resources[resourceKey] = buildResource(
        record,
        zoneVarRef,
        zoneId,
        existingId,
      );
    }
  }

  const pulumiConfig = {
    name: "cloudflare-dns",
    runtime: "yaml",
    description: `DNS configuration for ${domains.join(", ")}`,
    variables,
    resources,
  };

  process.stdout.write(Bun.YAML.stringify(pulumiConfig));
}

main();
