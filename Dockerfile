# Build stage: compile the Vite SPA into dist/.
# Node is pinned explicitly — nixpacks' auto-detected default was Node 18, which
# nixpkgs removed after EOL and which broke the build.
FROM node:22-alpine AS build

WORKDIR /app

# Copy manifests first so the dependency layer is cached across source changes.
COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN npm run build

# Runtime stage: Caddy serves dist/ directly, no Node in the final image.
FROM caddy:2-alpine

WORKDIR /srv

COPY Caddyfile /srv/Caddyfile
# Normalizes/validates the Caddyfile at build time: a syntax error fails the
# build instead of crash-looping the deploy.
RUN caddy fmt --overwrite /srv/Caddyfile

COPY --from=build /app/dist /srv/dist

EXPOSE 8080

CMD ["caddy", "run", "--config", "/srv/Caddyfile", "--adapter", "caddyfile"]
