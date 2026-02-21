# Papichulo Backend (Database Version)

This backend now uses a real database via Prisma (SQLite for MVP).

## Setup

1. Install dependencies:
   - `npm install`
2. Create local env file:
   - Copy `.env.example` to `.env`
3. Run DB migration:
   - `npm run prisma:migrate`
4. Seed menu data:
   - `npm run prisma:seed`
5. Start server:
   - `npm start`

## Environment Variables

- `DATABASE_URL`: Prisma datasource URL.
- `ALLOWED_ORIGINS`: Comma-separated CORS allowlist.
- `RATE_LIMIT_WINDOW_MS`: API rate-limit window in ms.
- `RATE_LIMIT_MAX`: Max requests per window for `/api`.
- `ADMIN_API_KEY` (optional): If set, admin routes require `x-admin-key`.
- `OTP_PROVIDER`: `console` (dev) or `twilio` (real SMS).
- `EXPOSE_DEBUG_OTP`: `true/false` (shows `debugOtp` in API response when enabled).
- `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_FROM_NUMBER`: Required for real SMS OTP delivery.

## API Endpoints

- `GET /health`
- `GET /api/menu`
- `GET /api/orders`
- `POST /api/orders`
- `PATCH /api/orders/:id/status` (admin)
- `POST /api/auth/send-otp`
- `POST /api/auth/verify-otp`

## Notes

- DB file is local: `backend/dev.db`
- To deploy with PostgreSQL later, switch datasource in `prisma/schema.prisma` and update `DATABASE_URL`.

## Real OTP (Twilio)

1. Set these in `.env`:
   - `OTP_PROVIDER=twilio`
   - `TWILIO_ACCOUNT_SID=...`
   - `TWILIO_AUTH_TOKEN=...`
   - `TWILIO_FROM_NUMBER=...`
2. Restart backend: `npm start`
3. Call `POST /api/auth/send-otp` with 10-digit phone.
4. Enter SMS OTP in UI; backend verifies via stored code + expiry.
