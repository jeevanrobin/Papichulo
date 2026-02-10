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

## API Endpoints

- `GET /health`
- `GET /api/menu`
- `GET /api/orders`
- `POST /api/orders`
- `PATCH /api/orders/:id/status` (admin)

## Notes

- DB file is local: `backend/dev.db`
- To deploy with PostgreSQL later, switch datasource in `prisma/schema.prisma` and update `DATABASE_URL`.
