# Deploy and Host Comp AI CRM on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/agentic-crm?referralCode=sLjDXb&utm_medium=integration&utm_source=button&utm_campaign=agentic-crm)

[Comp AI CRM](https://github.com/trycompai/crm) is an open-source CRM built for AI agents. Sign in with Google or Microsoft and it builds your contacts, companies and deals from your own email and calendar. A research agent works its own queue in the background: it keeps a dossier on every account, books its own follow-ups and records what it could and couldn't check. This template runs release 1.16.0 as five Railway services and keeps upstream's own sign-in, encryption and cron jobs.

## About Hosting Comp AI CRM

Upstream deploys to Vercel; this template runs the same code on Railway, built from the release tag:

- **CRM**: the Next.js app, the only public service. It proxies `/api/*` to the API on the private network, so your browser only ever talks to one domain, and Google's sign-in callback lands there too.
- **API**: NestJS with Better Auth, tRPC and the mailbox sync. It applies database migrations before it starts.
- **Agent**: the research agent on Vercel's eve framework, run with `eve start`. Its durable sessions live on a volume, and its bash tools use eve's built-in sandbox.
- **Cron**: every five minutes it runs the Gmail/Outlook sync, plus the daily jobs upstream schedules on Vercel (currency rates, tracking and archive retention, usage rollup).
- **Postgres**: everything else.

Secrets (session signing, the agent bridge, the cron token and the two encryption keys) are generated when you deploy.

## Common Use Cases

- A CRM that fills itself in from your Gmail or Outlook and calendar history
- Account research before a call: who someone is, what their company does, recent news
- A small team's pipeline of companies, contacts and deals, with sign-in limited to your domain
- Website visitor tracking and forms feeding contacts into the CRM

## Dependencies for Comp AI CRM Hosting

- A Google Cloud OAuth client (or a Microsoft Entra app) for sign-in. The CRM has no password login.
- Optional: a Vercel AI Gateway key for the research agent's model, and a Perplexity key for web research

### Deployment Dependencies

- [Comp AI CRM on GitHub](https://github.com/trycompai/crm)
- [Google OAuth client setup](https://console.cloud.google.com/apis/credentials)
- [Vercel AI Gateway](https://vercel.com/docs/ai-gateway)
- [Template source](https://github.com/two-workspaces/comp-crm)

### Implementation Details

**Before you deploy:** set `ALLOWED_SIGN_IN` (on the API service) to your email address or your company's domain. Only those people can sign in.

**Setting up Google sign-in:**

1. Deploy, then copy the CRM service's domain (Settings → Networking).
2. In Google Cloud Console, enable the **Gmail API** and **Google Calendar API**, then create an OAuth client of type **Web application** with the redirect URI `https://‹your CRM domain›/api/auth/callback/google`. On Google Workspace, set the consent screen to **Internal**: `gmail.readonly` is a restricted scope, and an External app needs Google's verification.
3. Put the client id and secret in `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` on the **API** service. The CRM service reads them from there. Railway redeploys both.
4. Open the CRM domain and sign in with Google.

Microsoft works the same way with `MICROSOFT_CLIENT_ID` and `MICROSOFT_CLIENT_SECRET`, and the redirect URI `https://‹your CRM domain›/api/auth/callback/microsoft`. Your own identity provider can be added under Settings → SSO once somebody has signed in.

**The research agent:** add `AI_GATEWAY_API_KEY` on the Agent service to give it a model, and `PERPLEXITY_API_KEY` to let it search the web. Without the gateway key the CRM works normally but the agent can't research. Pick the model under Settings.

**Custom domain:** add it to the CRM service, then set `APP_URL` and `API_URL` to `https://your-domain` on both the CRM and API services, and add the new redirect URI to your OAuth client.

Notes and limits:

- The API counts installs with anonymous, server-side usage telemetry (counts only, never names, contents or keys; see upstream's docs/telemetry.md). Set `CRM_TELEMETRY_DISABLED=1` on the API and Agent to turn it off.
- Contact photos are only stored with a Vercel Blob token (`BLOB_READ_WRITE_TOKEN` on the API and Agent). Without it, logos and avatars link to their source and photos fall back to initials.
- The agent's sandbox is an emulated shell with no network access, as upstream intends; it doesn't run real binaries.

## Why Deploy Comp AI CRM on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Comp AI CRM on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
