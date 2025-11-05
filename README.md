# Pocketvue

All-in-one, single-binary SaaS starter kit that combines a PocketBase backend with a Nuxt-powered frontend. Pocketvue bundles authentication, billing, email, file storage, and real-time examples so you can launch customer-facing products quickly without stitching together infrastructure.

## Table of Contents

- [Feature Highlights](#feature-highlights)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Project Layout](#project-layout)
- [Getting Started](#getting-started)
- [Requirements](#requirements)
- [Setup Checklist](#setup-checklist)
- [Local Development](#local-development)
- [Environment & Configuration](#environment--configuration)
- [Polar Payments](#polar-payments)
- [Email (SMTP)](#email-smtp)
- [OAuth2 Providers](#oauth2-providers)
- [Building for Production](#building-for-production)
- [Deploying the Binary](#deploying-the-binary)
  - [Deploying with Coolify](#deploying-with-coolify)
  - [Deploying Pocketbase on DigitalOcean](#deploying-pocketbase-on-digitalocean)
- [Useful Commands](#useful-commands)
- [Contributing & Support](#contributing--support)

## Feature Highlights

- **Authentication**: Email/password plus OAuth2 (Google, GitHub, and any PocketBase provider).
- **Subscriptions & Billing**: [Polar](https://polar.sh/) integration for checkout, customer portal, webhooks, and product sync.
- **UI/UX**: Nuxt 4 SPA, Tailwind-based [@nuxt/ui](https://ui.nuxt.com/), and prebuilt onboarding flows.
- **Email Delivery**: SMTP-ready templates and notifications on user lifecycle events.
- **File Storage**: PocketBase storage API with example image handling.
- **Realtime & API Examples**: Starter CRUD endpoints, live workspace demo, and typed PocketBase client.
- **Single Binary Deployment**: Bundle the generated frontend into the PocketBase binary for zero-config hosting.
- **Lightweight Hosting**: ~32 MB executable that happily runs on a $5/mo server.

## Tech Stack

- **PocketBase** – Go-powered backend framework handling auth, data, and file storage.
- **Go 1.24** – Custom routes, hooks, and the single-binary runtime.
- **Nuxt 4 (SPA mode)** – Frontend application framework with first-class DX.
- **@nuxt/ui & Tailwind CSS** – Component system and styling utilities.
- **VueUse** – Utility composables for Vue 3 applications.
- **Polar** – Subscription billing, checkout flows, and webhook events.

## Architecture

Pocketvue pairs a Go backend with a statically generated Nuxt frontend that is served directly from PocketBase:

```
[Nuxt 4 SPA] --build--> backend/ui/dist --> bundled into PocketBase binary
        |
        v
[PocketBase] --routes--> REST APIs, webhooks, auth, real-time
        |
        v
[Polar, SMTP, OAuth2 providers]
```

- `backend`: PocketBase app, custom routes, services, hooks, and migrations.
- `frontend`: Nuxt SPA compiled into `backend/ui/dist` and shipped with the binary.
- `pnpm workspace`: Scripts orchestrate dev server, type generation, and builds.

## Project Layout

```
pocketvue/
├─ backend/              # PocketBase application (Go)
│  ├─ routes/            # REST handlers (Polar checkout, products, etc.)
│  ├─ hooks/             # PocketBase lifecycle hooks (user onboarding)
│  ├─ services/          # Integrations (Polar client, emails)
│  └─ ui/dist            # Generated frontend assets (filled on build)
├─ frontend/             # Nuxt SPA
│  ├─ app/               # Pages, components, layouts
│  └─ types/pocketbase.ts# Generated PocketBase TypeScript types
├─ package.json          # Workspace scripts (dev, build, migrate, typegen)
└─ pnpm-workspace.yaml
```

## Getting Started

The fastest way to try Pocketvue is with the prebuilt PocketBase binary:

1. Download the archive for your platform from the [releases page](https://github.com/fayazara/pocketvue/releases).
2. Unzip and run the binary:
   ```bash
   ./pocketvue serve
   ```
3. Visit `http://127.0.0.1:8090/_/` and create the super-admin account when prompted.
4. Configure SMTP, OAuth, Polar, and other settings in the PocketBase dashboard (see [Environment & Configuration](#environment--configuration)).

PocketBase stores all data and configuration in `pb_data/` alongside the executable, making it easy to move between environments.

## Requirements

To work with the source repository you'll need:

- Go ≥ 1.24 (toolchain managed via `backend/go.mod`)
- Node ≥ 20 and pnpm ≥ 10.18.2 (`corepack enable pnpm` recommended)
- Polar sandbox account (for payments testing)
- SMTP credentials (for email delivery)

## Setup Checklist

Quick setup guide for local development:

- [ ] Install prerequisites: Go ≥ 1.24, Node ≥ 20, and pnpm ≥ 10.18.2
- [ ] Clone the repository and navigate to the project directory
- [ ] Install workspace dependencies: `pnpm install`
- [ ] Install frontend dependencies: `cd frontend && pnpm install && cd ..`
- [ ] Create `.env` in the repo root with PocketBase admin credentials (see [Environment & Configuration](#environment--configuration))
- [ ] Create `backend/.env` with `FRONTEND_URL` and Polar credentials (optional for initial setup)
- [ ] Start the development server: `pnpm dev`
- [ ] Visit `http://localhost:8090/_/` and create the super-admin account
- [ ] Configure Application URL in PocketBase dashboard (`_ > Settings > Application`)
- [ ] (Optional) Set up SMTP, OAuth providers, and Polar webhooks (see respective sections below)
- [ ] (Optional) Generate TypeScript types: `pnpm typegen`

## Local Development

Run the full stack asynchronously with shared tooling:

```bash
# install workspace deps
pnpm install

# install frontend deps (workspace keeps its own lockfile)
cd frontend && pnpm install && cd ..

# start PocketBase (Go) + Nuxt dev server with hot reload
pnpm dev
```

- Frontend runs on `http://localhost:3000`.
- PocketBase admin UI and REST API run on `http://localhost:8090`.
- The development backend uses `go run -tags dev` so migrations auto-update when editing collections via the dashboard.

Stop the dev process with `Ctrl + C`. PocketBase writes data into `backend/pb_data` during development; delete it if you need a clean slate.

## Environment & Configuration

Pocketvue relies on two environment files:

| Location           | Purpose                                      | Keys                                                        |
| ------------------ | -------------------------------------------- | ----------------------------------------------------------- |
| `.env` (repo root) | PocketBase type generation (`pnpm typegen`)  | `PB_TYPEGEN_URL`, `PB_TYPEGEN_EMAIL`, `PB_TYPEGEN_PASSWORD` |
| `backend/.env`     | Runtime configuration consumed by PocketBase | `FRONTEND_URL`, `POLAR_*`, and any custom secrets           |

Example root `.env`:

```bash
PB_TYPEGEN_URL=http://127.0.0.1:8090
PB_TYPEGEN_EMAIL=admin@example.com
PB_TYPEGEN_PASSWORD=strong-password
```

Example `backend/.env` for local testing:

```bash
FRONTEND_URL=http://localhost:3000
POLAR_ENVIRONMENT=development
POLAR_ACCESS_TOKEN=polar_oat_access_token
POLAR_WEBHOOK_SECRET=polar_whs_secret
```

After starting the app for the first time:

1. Open `_ > Settings > Application` in the PocketBase dashboard and set the Application URL.
2. Configure SMTP, OAuth providers, and file storage endpoints under `_ > Settings`.
3. (Optional) Update generated types once models change:
   ```bash
   pnpm typegen
   ```

## Polar Payments

Pocketvue uses Polar.sh for subscriptions and payments:

1. Create a Polar account , use the sandbox environment for testing [https://sandbox.polar.sh/](https://sandbox.polar.sh/) or production [https://polar.sh/](https://polar.sh/)
2. Generate an **Access Token** from `Dashboard > Settings > Developer`.
3. Create a webhook endpoint (`Dashboard > Settings > Webhooks`) with the following events:
   - `order.created`, `order.paid`
   - `subscription.created`, `subscription.updated`, `subscription.canceled`, `subscription.revoked`
   - `product.created`, `product.updated`
4. Set the webhook format to `Raw` and point it to your deployment: `https://your-domain.com/api/polar-webhook`. For local testing use a tunnel such as [Localcan](https://www.localcan.com/) or ngrok.
5. Add the access token and webhook secret to `backend/.env`.

Products created in Polar automatically sync to Pocketvue via `backend/routes/polar_webhook.go`.

We have a `features` in the `polar_products` collection - you can add a JSON array manually in PocketBase to surface plan highlights in the UI. Here's a simple example:

```json
[
  {
    "icon": "lucide:sparkles",
    "label": "Expanded Access to GPT-5"
  },
  {
    "icon": "lucide:messages-square",
    "label": "Expanded messaging and uploads"
  },
  {
    "icon": "lucide:image",
    "label": "Expanded and faster image creation"
  },
  {
    "icon": "lucide:brain",
    "label": "Limited deep research"
  },
  {
    "icon": "lucide:telescope",
    "label": "Maximum deep research and agent mode"
  },
  {
    "icon": "lucide:git-compare",
    "label": "Projects & tasks"
  }
]
```

Icons use the Iconify library, you can get your icon keys from [icones.js.org](https://icones.js.org/)

## Email (SMTP)

Configure SMTP to send transactional emails:

1. Choose any email provider you prefer such as [Resend](https://resend.com/), [SendGrid](https://sendgrid.com/en-us), [AWS SES](https://aws.amazon.com/ses/), or [Zoho ZeptoMail](https://www.zoho.com/zeptomail/) and get the SMTP credentials.
2. In the PocketBase admin UI navigate to `_ > Settings > Mail settings`.
3. Enter SMTP host, port, username, password, and From address.
4. Save and send a test email before onboarding users.

> [!NOTE]
> For Digital Ocean users, all outbound SMTP ports are blocked by default, you need to contact their support to unblock them.

## OAuth2 Providers

Enable Google, GitHub, or any PocketBase-supported provider from the `users` auth collection settings.

- Redirect / callback URL: `https://your-domain.com/api/oauth2-redirect`
- For local development use your tunneling URL or `http://localhost:8090/api/oauth2-redirect` when testing with providers that allow localhost.
- Pocketvue ships with OAuth enabled by default; you need to add provider credentials in the PocketBase dashboard to get them working.

## Building for Production

Create a single binary that embeds the compiled frontend:

```bash
# from the repository root
pnpm build
```

This runs:

- `pnpm run build:frontend` → generates static assets into `backend/ui/dist`.
- `pnpm run build:backend` → builds the `pocketvue` binary.

Find the generated executable at `backend/pocketvue` (macOS/Linux) or `backend/pocketvue.exe` (Windows). Move it and the `pb_data` directory to your server or container.

## Deploying the Binary

Deploy Pocketvue just like any PocketBase application:

1. Copy the binary and `pb_data/` to your server (e.g. via `scp` or `rsync`).
2. Create a systemd service to keep it running:

   ```ini
   [Unit]
   Description=pocketvue

   [Service]
   Type=simple
   ExecStart=/srv/pocketvue/pocketvue serve yourdomain.com
   Restart=always
   RestartSec=5s
   StandardOutput=append:/srv/pocketvue/errors.log
   StandardError=append:/srv/pocketvue/errors.log
   Environment      = "FRONTEND_URL=https://yourdomain.com"
   Environment      = "POLAR_ENVIRONMENT=production"
   Environment      = "POLAR_ACCESS_TOKEN=polar_oat_access_token"
   Environment      = "POLAR_WEBHOOK_SECRET=polar_whs_secret"

   [Install]
   WantedBy=multi-user.target
   ```

3. Reload systemd, enable, and start the service:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable pocketvue
   sudo systemctl start pocketvue
   ```

### Deploying with Coolify

[Coolify](https://coolify.io/) is an open-source platform for deploying applications. Pocketvue includes Docker support for easy deployment.

#### Deployment Steps

1. **Create New Application** in Coolify:
   - Choose "Public Repository"
   - Repository URL: `https://github.com/fayazara/pocketvue`
   - Build Pack: `Dockerfile`
   - Port Exposes: `8090`

2. **Set Environment Variables**:
   ```bash
   FRONTEND_URL=https://your-domain.com
   POLAR_ENVIRONMENT=production
   POLAR_ACCESS_TOKEN=your_polar_access_token
   POLAR_WEBHOOK_SECRET=your_polar_webhook_secret
   ```

3. **Configure Persistent Storage**:
   - Add volume: Mount `/app/pb_data` (stores database and uploads)

4. **Set Domain** and click **Deploy** (~3-5 minutes)

#### Post-Deployment

1. Visit `https://your-domain.com/_/` and create admin account
2. Configure Application URL in Settings
3. Set up SMTP in Mail settings
4. (Optional) Configure OAuth providers with redirect URL: `https://your-domain.com/api/oauth2-redirect`
5. Add Polar webhook: `https://your-domain.com/api/polar-webhook`

#### Troubleshooting

- Ensure Port Exposes is `8090` and volume is mounted at `/app/pb_data`
- Verify `FRONTEND_URL` matches your domain
- Check build logs in Coolify for errors

### Deploying Pocketbase on DigitalOcean

Luke Pighetti [@luke_pighetti](https://x.com/luke_pighetti) has an excellent video on [deploying PocketBase to DigitalOcean](https://youtu.be/bBY4Qr8tpoQ?si=S6ibkironG3DM-sl).

## Useful Commands

| Command                    | Description                                           |
| -------------------------- | ----------------------------------------------------- |
| `pnpm dev`                 | Run Nuxt + PocketBase in development with live reload |
| `pnpm build`               | Generate the single-binary release                    |
| `pnpm run build:frontend`  | Only build the Nuxt SPA into `backend/ui/dist`        |
| `pnpm run build:backend`   | Build the PocketBase binary                           |
| `pnpm typegen`             | Regenerate PocketBase TypeScript types                |
| `pnpm generate:migrations` | Export PocketBase collection changes into migrations  |

## Contributing & Support

- License: [MIT](LICENSE)
- Report bugs or request features via [GitHub Issues](https://github.com/fayazara/pocketvue/issues)
- Sponsor ongoing development on [GitHub Sponsors](https://github.com/sponsors/fayazara)

Bug reports, feature ideas, and pull requests are always welcome.

Special thanks to Gani Georgiev for PocketBase and to the Nuxt ecosystem for the tooling that made this app possible.
