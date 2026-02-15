const jwt = require('jsonwebtoken');

function parseBearerToken(req) {
  const authHeader = req.headers.authorization;
  if (!authHeader || typeof authHeader !== 'string') return null;
  if (!authHeader.startsWith('Bearer ')) return null;
  return authHeader.slice(7).trim();
}

function makeRbacMiddleware({ jwtSecret, allowAdminKey = true }) {
  if (!jwtSecret) {
    throw new Error('RBAC middleware requires jwtSecret');
  }

  function requireRole(allowedRoles) {
    const normalizedRoles = new Set(
      allowedRoles.map((role) => String(role).toLowerCase()),
    );

    return (req, res, next) => {
      const adminKey = process.env.ADMIN_API_KEY;
      const providedKey = req.headers['x-admin-key'];
      if (allowAdminKey && adminKey && providedKey === adminKey) {
        req.user = { role: 'admin', authType: 'admin_key' };
        return next();
      }

      const token = parseBearerToken(req);
      if (!token) {
        return res.status(401).json({
          error: { code: 'UNAUTHORIZED', message: 'Missing auth token' },
        });
      }

      try {
        const payload = jwt.verify(token, jwtSecret);
        const role = String(payload.role || '').toLowerCase();
        if (!normalizedRoles.has(role)) {
          return res.status(403).json({
            error: { code: 'FORBIDDEN', message: 'Insufficient role permissions' },
          });
        }
        req.user = payload;
        return next();
      } catch (_) {
        return res.status(401).json({
          error: { code: 'UNAUTHORIZED', message: 'Invalid or expired auth token' },
        });
      }
    };
  }

  const requireAdmin = requireRole(['admin']);
  const requireAuth = requireRole(['admin', 'customer']);

  return { requireRole, requireAdmin, requireAuth };
}

module.exports = { makeRbacMiddleware };

