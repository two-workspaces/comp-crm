# Comp AI CRM on Railway: one image for the whole monorepo. The Next.js app, the NestJS API, the
# eve research agent and the cron job are separate Railway services that run it with a different
# CRM_ROLE (railway-start.sh).
# upgrade: skip  (the base images below follow upstream's own toolchain, not their registries)
FROM oven/bun:1.4.0 AS bun

FROM node:24-bookworm-slim
COPY --from=bun /usr/local/bin/bun /usr/local/bin/bun
RUN ln -s /usr/local/bin/bun /usr/local/bin/bunx \
  && apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates git openssl \
  && rm -rf /var/lib/apt/lists/*

# upgrade: github trycompai/crm
ARG CRM_VERSION=v1.16.0
RUN git clone --depth 1 --branch ${CRM_VERSION} https://github.com/trycompai/crm /app \
  && rm -rf /app/.git
WORKDIR /app

ENV NODE_ENV=production \
    TURBO_TELEMETRY_DISABLED=1 \
    NEXT_TELEMETRY_DISABLED=1
# Placeholders for the build only: prisma.config.ts and the env validation read them at import time.
# Next inlines NEXT_PUBLIC_API_URL into the app at build time; railway-start.sh swaps this
# placeholder for the API's private address when the app starts.
RUN DATABASE_URL=postgresql://build:build@127.0.0.1:5432/build \
    BETTER_AUTH_SECRET=build-only-placeholder-secret-0000000000 \
    ALLOWED_SIGN_IN=example.com \
    NEXT_PUBLIC_API_URL=http://crm-api.placeholder.invalid \
    CRM_TELEMETRY_DISABLED=1 \
    sh -c 'bun install --frozen-lockfile && bunx turbo run build --filter=app --filter=agent'

COPY railway-start.sh /usr/local/bin/railway-start.sh
COPY cron.ts /app/railway-cron.ts
RUN chmod 0755 /usr/local/bin/railway-start.sh
CMD ["/usr/local/bin/railway-start.sh"]
