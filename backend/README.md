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

## API Endpoints

- `GET /health`
- `GET /api/menu`
- `GET /api/orders`
- `POST /api/orders`

## Notes

- DB file is local: `backend/dev.db`
- To deploy with PostgreSQL later, switch datasource in `prisma/schema.prisma` and update `DATABASE_URL`.
