# Portfolio Website

Rails API backend + Vite React frontend for a freelance portfolio with blog CMS, scheduling, and OAuth integrations.

## Stack

- Ruby `3.4.2`, Rails `8.1`
- PostgreSQL
- React + TypeScript + Vite
- Foreman for running backend/frontend together

## Local setup

1. Copy env templates:
   - `cp .env.example .env`
   - `cp client/.env.example client/.env`
2. Install dependencies and prepare DB:
   - `bin/setup --skip-server`
3. Seed sample data:
   - `bin/rails db:seed`
4. Run both services:
   - `bin/dev`

App URLs:
- Frontend: `http://localhost:5173`
- Rails API: `http://localhost:3000`
- Admin UI: `http://localhost:5173/workspace-ops` (or whatever `VITE_ADMIN_PATH` is set to)

## Key endpoints

Public API:
- `GET /api/v1/public/profile_sections`
- `GET /api/v1/public/blog_posts`
- `GET /api/v1/public/blog_posts/:slug`
- `GET /api/v1/public/availability?timezone=UTC&days=14` (returns `days[]` and flattened `slots[]`)
- `POST /api/v1/public/meetings`
- `POST /api/v1/public/contacts`

Admin API:
- `POST /api/v1/admin/session`
- `GET/POST/PATCH/DELETE /api/v1/admin/blog_posts`
- `GET/POST/PATCH/DELETE /api/v1/admin/profile_sections`
- `GET/POST/PATCH/DELETE /api/v1/admin/availability_rules`
- `GET /api/v1/admin/meetings`
- `GET /api/v1/admin/integrations/status`
- `POST /api/v1/admin/integrations/google_exchange`
- `POST /api/v1/admin/integrations/zoom_exchange`

## OAuth setup

Add credentials in `.env`:
- `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`
- `ZOOM_CLIENT_ID`, `ZOOM_CLIENT_SECRET`

Add frontend OAuth env in `client/.env`:
- `VITE_GOOGLE_CLIENT_ID=<same Google client id>`
- `VITE_GOOGLE_OAUTH_REDIRECT_PATH=/oauth/google/callback`
- `VITE_ZOOM_CLIENT_ID=<your zoom oauth client id>`
- `VITE_ZOOM_OAUTH_REDIRECT_PATH=/oauth/zoom/callback`
- `VITE_ZOOM_OAUTH_REDIRECT_URI=<optional full https callback URL for ngrok/dev>`

Google OAuth callback URL examples:
- Dev: `http://localhost:5173/oauth/google/callback`
- Prod: `https://your-frontend-domain.com/oauth/google/callback`

Zoom OAuth callback URL examples:
- Dev: `http://localhost:5173/oauth/zoom/callback`
- Prod: `https://your-frontend-domain.com/oauth/zoom/callback`

If Zoom rejects localhost redirect URLs, set `VITE_ZOOM_OAUTH_REDIRECT_URI` to your public HTTPS URL
(for example an ngrok URL) and add that exact URL in Zoom OAuth redirect settings.

Booking provisioning uses background jobs:
- `ProvisionMeetingJob` creates Zoom meeting + Google Calendar event.
- Failed provisioning marks meeting status as `failed` with details in notes.

Availability source:
- Public booking availability is driven by Google Calendar free/busy data.
- Edit availability by blocking/unblocking time directly in your Google Calendar.

## CORS and domains

CORS allowlist comes from:
- `FRONTEND_ORIGINS=http://localhost:5173,http://127.0.0.1:5173`

For production, set frontend domain(s) in `FRONTEND_ORIGINS` and set:
- `PUBLIC_APP_URL=https://your-frontend-domain.com`

## Deployment

Suggested portfolio deployment:
- Frontend: Vercel / Netlify / Cloudflare Pages
- Backend: Render / Fly.io or VPS + Kamal
- Database: Managed Postgres

Existing deployment files:
- `Dockerfile`
- `config/deploy.yml` (Kamal)

## Verification

- Rails boot: `bin/rails runner "puts :ok"`
- Frontend build: `npm --prefix client run build`
- Test suite: `bin/rails test`
