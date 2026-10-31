// The cron jobs upstream declares in apps/api/vercel.json, as one Railway cron service that runs
// every five minutes: the mailbox sync every run, the daily jobs on the run that falls in their hour's
// first five minutes (UTC, as on Vercel).
const api = process.env.CRM_API_INTERNAL_URL;
const secret = process.env.CRON_SECRET;
if (!api || !secret) throw new Error("CRM_API_INTERNAL_URL and CRON_SECRET must be set");

const now = new Date();
const daily: Record<string, number> = {
	"/internal/tracking/retention": 4,
	"/internal/archive/prune": 5,
	"/internal/sync/rates": 6,
	"/internal/telemetry/rollup": 7,
};
const paths = ["/internal/sync/mailboxes"];
for (const [path, hour] of Object.entries(daily)) {
	if (now.getUTCHours() === hour && now.getUTCMinutes() < 5) paths.push(path);
}

let failed = false;
for (const path of paths) {
	try {
		const response = await fetch(`${api}${path}`, {
			method: "POST",
			headers: { authorization: `Bearer ${secret}` },
			signal: AbortSignal.timeout(240_000),
		});
		console.log(`${path} ${response.status} ${(await response.text()).slice(0, 300)}`);
		if (!response.ok) failed = true;
	} catch (error) {
		console.error(`${path} failed: ${error}`);
		failed = true;
	}
}
process.exit(failed ? 1 : 0);
