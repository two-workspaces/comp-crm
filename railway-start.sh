#!/bin/sh
# One image, four Railway services: CRM_ROLE picks which part of the monorepo this one runs.
set -eu

case "${CRM_ROLE:-}" in
app)
  # The app proxies /api/* to the API on the server side, so the browser only ever talks to the
  # app. Next baked the API address in at build time; point it at this project's API.
  grep -rlF "http://crm-api.placeholder.invalid" /app/apps/app/.next \
    | xargs -r sed -i "s#http://crm-api.placeholder.invalid#${CRM_API_INTERNAL_URL}#g"
  cd /app/apps/app
  exec bunx next start -H :: -p "${PORT:-3000}"
  ;;
api)
  # Upstream migrates in its Vercel production build; here it happens before the API starts.
  cd /app/packages/db
  bunx prisma migrate deploy
  cd /app/apps/api
  exec bun src/main.ts
  ;;
agent)
  cd /app/apps/agent
  exec bun run start
  ;;
cron)
  exec bun /app/railway-cron.ts
  ;;
*)
  echo "railway: set CRM_ROLE to app, api, agent or cron" >&2
  exit 1
  ;;
esac
