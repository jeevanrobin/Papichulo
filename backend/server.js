const express = require('express');
const cors = require('cors');
const { PrismaClient } = require('@prisma/client');
const rateLimit = require('express-rate-limit');
const { z } = require('zod');

const app = express();
const PORT = process.env.PORT || 3001;
const prisma = new PrismaClient();
const asyncHandler = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);
const allowedOrigins = (process.env.ALLOWED_ORIGINS || 'https://jeevanrobin.github.io,http://localhost:3001,http://localhost:3011,http://localhost:58995')
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);
const rateLimitWindowMs = Number(process.env.RATE_LIMIT_WINDOW_MS || 60_000);
const rateLimitMax = Number(process.env.RATE_LIMIT_MAX || 120);

class ApiError extends Error {
  constructor(status, code, message, details = null) {
    super(message);
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

const orderCreateSchema = z.object({
  customerName: z.string().trim().min(2).max(80),
  phone: z.string().trim().regex(/^[0-9+\-\s]{7,15}$/),
  address: z.string().trim().min(5).max(300),
  latitude: z.number().gte(-90).lte(90),
  longitude: z.number().gte(-180).lte(180),
  paymentMethod: z.string().trim().min(2).max(50),
  items: z.array(
    z.object({
      name: z.string().trim().min(1).max(120),
      price: z.number().nonnegative(),
      quantity: z.number().int().positive().max(50),
    }),
  ).min(1).max(50),
  totalAmount: z.number().nonnegative(),
}).strict();

const orderStatusSchema = z.object({
  status: z.enum(['new', 'preparing', 'out_for_delivery', 'delivered', 'cancelled']),
}).strict();

const deliveryConfigSchema = z.object({
  storeLatitude: z.number().gte(-90).lte(90),
  storeLongitude: z.number().gte(-180).lte(180),
  radiusKm: z.number().gt(0).lte(50),
}).strict();

function makeOrderId() {
  const ts = Date.now().toString().slice(-8);
  const random = Math.floor(1000 + Math.random() * 9000);
  return `ORD${ts}${random}`;
}

function sendError(res, status, code, message, details = null) {
  return res.status(status).json({
    error: {
      code,
      message,
      details,
    },
  });
}

function haversineKm(lat1, lon1, lat2, lon2) {
  const toRad = (v) => (v * Math.PI) / 180;
  const earthRadiusKm = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a = Math.sin(dLat / 2) ** 2
    + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return earthRadiusKm * c;
}

async function getDeliveryConfig() {
  return prisma.deliveryConfig.upsert({
    where: { id: 1 },
    update: {},
    create: {
      id: 1,
      storeLatitude: 17.385044,
      storeLongitude: 78.486671,
      radiusKm: 10,
    },
  });
}

function isAllowedOrigin(origin) {
  if (!origin) return true;
  if (allowedOrigins.includes(origin)) return true;
  return /^http:\/\/localhost:\d+$/.test(origin);
}

function validateBody(schema) {
  return (req, _, next) => {
    const parsed = schema.safeParse(req.body);
    if (!parsed.success) {
      throw new ApiError(
        400,
        'VALIDATION_ERROR',
        'Invalid request body',
        parsed.error.issues.map((issue) => ({
          path: issue.path.join('.'),
          message: issue.message,
        })),
      );
    }
    req.body = parsed.data;
    next();
  };
}

function requireAdmin(req, _, next) {
  const adminKey = process.env.ADMIN_API_KEY;
  if (!adminKey) {
    return next();
  }
  const provided = req.headers['x-admin-key'];
  if (provided !== adminKey) {
    throw new ApiError(401, 'UNAUTHORIZED', 'Missing or invalid admin key');
  }
  next();
}

app.use(cors({
  origin: (origin, callback) => {
    if (isAllowedOrigin(origin)) return callback(null, true);
    return callback(new Error(`Origin not allowed: ${origin}`));
  },
}));
app.use(express.json({ limit: '1mb' }));
app.use('/api', rateLimit({
  windowMs: rateLimitWindowMs,
  max: rateLimitMax,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (_, res) => {
    sendError(res, 429, 'RATE_LIMITED', 'Too many requests, please try again later.');
  },
}));

app.get('/health', asyncHandler(async (_, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.json({
      ok: true,
      service: 'papichulo-backend',
      db: 'connected',
      uptimeSeconds: Math.round(process.uptime()),
    });
  } catch (_) {
    sendError(res, 500, 'DB_UNAVAILABLE', 'Database is not connected.');
  }
}));

app.get('/api/menu', asyncHandler(async (_, res) => {
  const menu = await prisma.menuItem.findMany({
    orderBy: [{ category: 'asc' }, { name: 'asc' }],
  });
  res.json(
    menu.map((item) => ({
      name: item.name,
      category: item.category,
      type: item.type,
      ingredients: item.ingredients,
      imageUrl: item.imageUrl,
      price: item.price,
      rating: item.rating,
    })),
  );
}));

app.get('/api/delivery-config', asyncHandler(async (_, res) => {
  const config = await getDeliveryConfig();
  res.json({
    storeLatitude: config.storeLatitude,
    storeLongitude: config.storeLongitude,
    radiusKm: config.radiusKm,
    updatedAt: config.updatedAt,
  });
}));

app.put('/api/delivery-config', requireAdmin, validateBody(deliveryConfigSchema), asyncHandler(async (req, res) => {
  const updated = await prisma.deliveryConfig.upsert({
    where: { id: 1 },
    update: req.body,
    create: {
      id: 1,
      ...req.body,
    },
  });

  res.json({
    storeLatitude: updated.storeLatitude,
    storeLongitude: updated.storeLongitude,
    radiusKm: updated.radiusKm,
    updatedAt: updated.updatedAt,
  });
}));

app.get('/api/geocode', asyncHandler(async (req, res) => {
  const address = String(req.query.address || '').trim();
  if (address.length < 5) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'Address must be at least 5 characters');
  }

  const url = `https://nominatim.openstreetmap.org/search?format=json&limit=1&q=${encodeURIComponent(address)}`;
  const response = await fetch(url, {
    headers: {
      'User-Agent': 'papichulo-backend/1.0',
      'Accept': 'application/json',
    },
  });

  if (!response.ok) {
    throw new ApiError(502, 'GEOCODE_UNAVAILABLE', 'Unable to resolve address right now.');
  }

  const payload = await response.json();
  if (!Array.isArray(payload) || payload.length === 0) {
    throw new ApiError(404, 'ADDRESS_NOT_FOUND', 'Could not find this address on map.');
  }

  const first = payload[0];
  res.json({
    latitude: Number(first.lat),
    longitude: Number(first.lon),
    label: String(first.display_name || address),
  });
}));

app.get('/api/orders', requireAdmin, asyncHandler(async (_, res) => {
  const orders = await prisma.order.findMany({
    include: { items: true },
    orderBy: { createdAt: 'desc' },
  });

  res.json(
    orders.map((order) => ({
      id: order.id,
      customerName: order.customerName,
      phone: order.phone,
      address: order.address,
      latitude: order.latitude,
      longitude: order.longitude,
      paymentMethod: order.paymentMethod,
      items: order.items.map((item) => ({
        name: item.name,
        price: item.price,
        quantity: item.quantity,
      })),
      totalAmount: order.totalAmount,
      status: order.status,
      createdAt: order.createdAt,
    })),
  );
}));

app.post('/api/orders', validateBody(orderCreateSchema), asyncHandler(async (req, res) => {
  const {
    customerName,
    phone,
    address,
    latitude,
    longitude,
    paymentMethod,
    items,
    totalAmount,
  } = req.body;
  const config = await getDeliveryConfig();
  const distanceKm = haversineKm(
    config.storeLatitude,
    config.storeLongitude,
    latitude,
    longitude,
  );
  if (distanceKm > config.radiusKm) {
    throw new ApiError(
      400,
      'OUTSIDE_DELIVERY_ZONE',
      `Delivery available within ${config.radiusKm.toFixed(1)} km only.`,
      { distanceKm: Number(distanceKm.toFixed(2)), radiusKm: config.radiusKm },
    );
  }

  const orderPayload = {
    id: makeOrderId(),
    customerName,
    phone,
    address,
    latitude,
    longitude,
    paymentMethod,
    totalAmount,
    status: 'new',
  };

  const created = await prisma.order.create({
    data: {
      ...orderPayload,
      items: {
        create: items.map((item) => ({
          name: item.name,
          price: item.price,
          quantity: item.quantity,
        })),
      },
    },
    include: { items: true },
  });

  return res.status(201).json({
    id: created.id,
    customerName: created.customerName,
    phone: created.phone,
    address: created.address,
    latitude: created.latitude,
    longitude: created.longitude,
    paymentMethod: created.paymentMethod,
    items: created.items.map((item) => ({
      name: item.name,
      price: item.price,
      quantity: item.quantity,
    })),
    totalAmount: created.totalAmount,
    status: created.status,
    createdAt: created.createdAt,
  });
}));

app.patch('/api/orders/:id/status', requireAdmin, validateBody(orderStatusSchema), asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;
  const updated = await prisma.order.update({
    where: { id },
    data: { status },
    include: { items: true },
  });
  res.json({
    id: updated.id,
    status: updated.status,
    createdAt: updated.createdAt,
  });
}));

app.use((_, res) => {
  sendError(res, 404, 'NOT_FOUND', 'Route not found.');
});

app.use((error, _, res, __) => {
  if (error instanceof ApiError) {
    return sendError(res, error.status, error.code, error.message, error.details);
  }

  if (error.name === 'ZodError') {
    return sendError(res, 400, 'VALIDATION_ERROR', 'Invalid request body', error.issues);
  }

  if (error.type === 'entity.parse.failed') {
    return sendError(res, 400, 'INVALID_JSON', 'Malformed JSON request body.');
  }

  if (typeof error.message === 'string' && error.message.startsWith('Origin not allowed')) {
    return sendError(res, 403, 'CORS_BLOCKED', error.message);
  }

  console.error('API error:', error);
  return sendError(res, 500, 'INTERNAL_SERVER_ERROR', 'Internal server error');
});

async function start() {
  try {
    await prisma.$connect();
    app.listen(PORT, () => {
      console.log(`Papichulo backend running on http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error('Failed to start backend:', error.message);
    process.exit(1);
  }
}

start();
