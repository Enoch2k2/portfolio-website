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

## Booking configuration

Booking availability is generated server-side by `Booking::AvailabilityService` and enforced again
when a meeting request is submitted. This keeps calendar UI behavior and backend validation aligned.

Environment variables in `.env`:

- `BOOKING_DAY_START_HOUR` (default `9`)
  - Start hour for bookable windows (24h local time in the selected booking timezone).
- `BOOKING_DAY_END_HOUR` (default `17`)
  - End hour for bookable windows.
- `BOOKING_WEEKDAYS` (default `1,2,3,4,5`)
  - Allowed weekdays (`0=Sun ... 6=Sat`).
- `BOOKING_MIN_NOTICE_HOURS` (default `24`)
  - Minimum advance notice required to book a slot.
  - Example: `24` means users can only pick slots at least 24 hours from "now".

Timezone behavior:

- The `/book` page uses a timezone dropdown with friendly labels (Eastern, Central, etc.) and GMT offsets.
- The selected timezone is sent as a valid IANA timezone (for example `America/Chicago`).
- Availability requests use `GET /api/v1/public/availability?timezone=<IANA>&days=<n>`.

Practical examples:

- Require 48-hour notice:
  - `BOOKING_MIN_NOTICE_HOURS=48`
- Include Saturdays:
  - `BOOKING_WEEKDAYS=1,2,3,4,5,6`
- Shift booking window to 10am-6pm:
  - `BOOKING_DAY_START_HOUR=10`
  - `BOOKING_DAY_END_HOUR=18`

## Operations playbook

### Daily scheduling workflow

- Keep your Google Calendar as the source of truth for busy/free time.
- Block focus periods and personal time directly in Google Calendar to remove those slots from public booking.
- Use `BOOKING_MIN_NOTICE_HOURS` to protect prep time before calls.
- Review incoming meetings in admin (`/workspace-ops`) and monitor status transitions (`tentative`, `confirmed`, `failed`).

### Holiday and time-off handling

- Add all-day or timed events in Google Calendar for holidays/PTO.
- For partial days, add specific busy blocks (for example, `13:00-17:00`) to keep morning slots open.
- If you know you'll be unavailable for an extended period, consider temporarily increasing `BOOKING_MIN_NOTICE_HOURS`.

### Quick troubleshooting

- **No slots appear on `/book`**
  - Verify Google integration is connected in admin Integrations.
  - Confirm timezone selection is correct for your region.
  - Check `BOOKING_WEEKDAYS`, start/end hour env values, and `BOOKING_MIN_NOTICE_HOURS`.
  - Check your Google Calendar for conflicting events.

- **Meeting request submitted but not fully provisioned**
  - Confirm background job processing is running in your `bin/dev` process set.
  - Review Rails logs for OAuth token refresh, Google API, or Zoom API errors.
  - Re-authenticate Google/Zoom if tokens are expired.

- **Times appear shifted**
  - Verify user-selected timezone on `/book`.
  - Ensure server and frontend env values are current after editing `.env` files.
  - Restart dev processes after env changes (`bin/dev`).

### Safe change process

- Change one booking env var at a time.
- Restart services and test `/book` manually after each change.
- Run automated checks:
  - `bundle exec rspec spec/services/booking/availability_service_spec.rb`
  - `npm --prefix client run test`

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
- Rails tests (RSpec): `bundle exec rspec`
- Frontend tests (RTL + Vitest): `npm --prefix client run test`
