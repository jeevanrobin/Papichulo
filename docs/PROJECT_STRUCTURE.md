# Papichulo - Recommended Full-Stack Structure

```text
papichulo/
|-- Jenkinsfile
|-- scripts/
|   `-- deploy.sh
|-- .env.dev.example
|-- .env.prod.example
|-- lib/                        # Flutter frontend
|-- web/
|-- backend/
|   |-- server.js
|   |-- middleware/
|   |   `-- rbac.js
|   |-- prisma/
|   |   |-- schema.prisma
|   |   `-- migrations/
|   |-- .env.dev.example
|   `-- .env.prod.example
`-- docs/
    `-- PROJECT_STRUCTURE.md
```

## Jenkins Credentials Required

- `papichulo-ssh-key` (SSH private key credential)
- `papichulo-remote-host` (Secret text, e.g. `dev.your-host.com`)
- `papichulo-remote-user` (Secret text, e.g. `deploy`)
- `papichulo-backend-env-dev-file` (Secret file content of backend `.env.dev`)
- `papichulo-backend-env-prod-file` (Secret file content of backend `.env.prod`)

## Branch Deployment Rules

- `dev` branch:
  - Uses `papichulo-backend-env-dev-file`
  - Deploys to development target
- `main` branch:
  - Uses `papichulo-backend-env-prod-file`
  - Deploys to production target

## Notes

- Backend admin routes are protected using RBAC (`backend/middleware/rbac.js`).
- Existing `server.js` already enforces admin/customer role checks for order/admin APIs.
- `scripts/deploy.sh` currently uses `rsync + ssh + systemctl` and can be adapted to Docker if needed.

