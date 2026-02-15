const express = require('express');
const cors = require('cors');
const { PrismaClient } = require('@prisma/client');
const rateLimit = require('express-rate-limit');
const { z } = require('zod');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { WebSocketServer } = require('ws');
const { makeRbacMiddleware } = require('./middleware/rbac');

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
const googleMapsApiKey = process.env.GOOGLE_MAPS_API_KEY || '';
const jwtSecret = process.env.JWT_SECRET || 'papichulo-dev-secret-change-this';
const jwtExpiresIn = process.env.JWT_EXPIRES_IN || '7d';
const wsAdminClients = new Set();
const { requireAdmin, requireAuth } = makeRbacMiddleware({
  jwtSecret,
  allowAdminKey: true,
});

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
  status: z.enum(['new', 'accepted', 'preparing', 'out_for_delivery', 'delivered', 'cancelled']),
}).strict();

const adminOrderStatusSchema = z.object({
  orderId: z.string().trim().min(3),
  status: z.enum(['new', 'accepted', 'preparing', 'out_for_delivery', 'delivered', 'cancelled']),
}).strict();

const deliveryConfigSchema = z.object({
  storeLatitude: z.number().gte(-90).lte(90),
  storeLongitude: z.number().gte(-180).lte(180),
  radiusKm: z.number().gt(0).lte(50),
}).strict();

const signupSchema = z.object({
  name: z.string().trim().min(2).max(80),
  email: z.string().trim().email().max(120),
  phone: z.string().trim().regex(/^[0-9+\-\s]{7,15}$/).optional(),
  password: z.string().min(6).max(100),
}).strict();

const loginSchema = z.object({
  email: z.string().trim().email().max(120),
  password: z.string().min(6).max(100),
}).strict();

const otpSendSchema = z.object({
  phone: z.string().trim().regex(/^[0-9]{10}$/),
}).strict();

const otpVerifySchema = z.object({
  phone: z.string().trim().regex(/^[0-9]{10}$/),
  otp: z.string().trim().regex(/^[0-9]{6}$/),
}).strict();

const cartSchema = z.object({
  items: z.array(
    z.object({
      name: z.string().trim().min(1).max(120),
      price: z.number().nonnegative(),
      quantity: z.number().int().positive().max(50),
    }),
  ).min(1).max(50),
}).strict();

const paymentSchema = z.object({
  orderId: z.string().trim().min(3),
  amount: z.number().positive(),
  method: z.enum(['UPI', 'CARD', 'WALLET', 'COD', 'MOCK_ONLINE']),
}).strict();

const menuItemCreateSchema = z.object({
  name: z.string().trim().min(2).max(120),
  category: z.string().trim().min(2).max(80),
  type: z.enum(['Veg', 'Non-Veg']),
  ingredients: z.array(z.string().trim().min(1).max(80)).min(1).max(30),
  imageUrl: z.string().trim().url().optional().or(z.literal('')),
  price: z.number().positive().max(100000),
  rating: z.number().gte(0).lte(5).default(4.5),
  available: z.boolean().default(true),
}).strict();

const menuItemUpdateSchema = menuItemCreateSchema.partial().strict();

function toUserResponse(user) {
  return {
    id: user.id,
    name: user.name,
    email: user.email,
    phone: user.phone,
    role: user.role,
    createdAt: user.createdAt,
  };
}

function normalizePhone(phone) {
  return String(phone || '').replace(/[^0-9]/g, '').slice(-10);
}

function generateOtpCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

function signUserToken(user) {
  return jwt.sign(
    {
      sub: String(user.id),
      role: user.role,
      email: user.email,
      name: user.name,
    },
    jwtSecret,
    { expiresIn: jwtExpiresIn },
  );
}

function parseBearerToken(req) {
  const authHeader = req.headers.authorization;
  if (!authHeader || typeof authHeader !== 'string') return null;
  if (!authHeader.startsWith('Bearer ')) return null;
  return authHeader.slice(7).trim();
}

function parseBearerTokenFromString(headerValue) {
  if (!headerValue || typeof headerValue !== 'string') return null;
  if (!headerValue.startsWith('Bearer ')) return null;
  return headerValue.slice(7).trim();
}

function getOptionalUserIdFromRequest(req) {
  const token = parseBearerToken(req);
  if (!token) return null;
  try {
    const payload = jwt.verify(token, jwtSecret);
    const userId = Number(payload.sub);
    if (!Number.isInteger(userId) || userId <= 0) return null;
    return userId;
  } catch (_) {
    return null;
  }
}

function getOptionalAuthPayload(req) {
  const token = parseBearerToken(req);
  if (!token) return null;
  try {
    return jwt.verify(token, jwtSecret);
  } catch (_) {
    return null;
  }
}

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

async function geocodeAddress(address) {
  if (googleMapsApiKey) {
    const url = `https://maps.googleapis.com/maps/api/geocode/json?address=${encodeURIComponent(address)}&key=${googleMapsApiKey}`;
    const response = await fetch(url);
    if (!response.ok) {
      throw new ApiError(502, 'GEOCODE_UNAVAILABLE', 'Unable to resolve address right now.');
    }
    const payload = await response.json();
    if (!payload || payload.status !== 'OK' || !Array.isArray(payload.results) || payload.results.length === 0) {
      throw new ApiError(404, 'ADDRESS_NOT_FOUND', 'Could not find this address on map.');
    }
    const first = payload.results[0];
    return {
      latitude: Number(first.geometry.location.lat),
      longitude: Number(first.geometry.location.lng),
      label: String(first.formatted_address || address),
    };
  }

  const url = `https://nominatim.openstreetmap.org/search?format=json&limit=1&q=${encodeURIComponent(address)}`;
  const response = await fetch(url, {
    headers: {
      'User-Agent': 'papichulo-backend/1.0',
      Accept: 'application/json',
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
  return {
    latitude: Number(first.lat),
    longitude: Number(first.lon),
    label: String(first.display_name || address),
  };
}

async function reverseGeocode(latitude, longitude) {
  if (googleMapsApiKey) {
    const url = `https://maps.googleapis.com/maps/api/geocode/json?latlng=${encodeURIComponent(`${latitude},${longitude}`)}&key=${googleMapsApiKey}`;
    const response = await fetch(url);
    if (!response.ok) {
      throw new ApiError(502, 'GEOCODE_UNAVAILABLE', 'Unable to resolve location right now.');
    }
    const payload = await response.json();
    if (!payload || payload.status !== 'OK' || !Array.isArray(payload.results) || payload.results.length === 0) {
      throw new ApiError(404, 'LOCATION_NOT_FOUND', 'Could not resolve this location.');
    }
    const first = payload.results[0];
    return {
      label: String(first.formatted_address || `${latitude},${longitude}`),
    };
  }

  const url = `https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${encodeURIComponent(latitude)}&lon=${encodeURIComponent(longitude)}`;
  const response = await fetch(url, {
    headers: {
      'User-Agent': 'papichulo-backend/1.0',
      Accept: 'application/json',
    },
  });
  if (!response.ok) {
    throw new ApiError(502, 'GEOCODE_UNAVAILABLE', 'Unable to resolve location right now.');
  }
  const payload = await response.json();
  const label = String(payload.display_name || '').trim();
  if (!label) {
    throw new ApiError(404, 'LOCATION_NOT_FOUND', 'Could not resolve this location.');
  }
  return { label };
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

function toOrderResponse(order) {
  return {
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
  };
}

function broadcastOrderEvent(event) {
  const payload = JSON.stringify(event);
  for (const client of wsAdminClients) {
    if (client.readyState === 1) {
      client.send(payload);
    }
  }
}

function isAdminWebSocketRequest(requestUrl) {
  const parsed = new URL(requestUrl || '/ws/orders', 'http://localhost');
  const adminKey = parsed.searchParams.get('adminKey') || '';
  const token =
    parsed.searchParams.get('token')
    || parseBearerTokenFromString(parsed.searchParams.get('authorization'));

  const expectedAdminKey = process.env.ADMIN_API_KEY || '';
  if (expectedAdminKey && adminKey && adminKey === expectedAdminKey) {
    return true;
  }
  if (!token) return false;
  try {
    const payload = jwt.verify(token, jwtSecret);
    return String(payload.role || '').toLowerCase() === 'admin';
  } catch (_) {
    return false;
  }
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
    where: { available: true },
    orderBy: [{ category: 'asc' }, { name: 'asc' }],
  });
  res.json(
    menu.map((item) => ({
      id: item.id,
      name: item.name,
      category: item.category,
      type: item.type,
      ingredients: item.ingredients,
      imageUrl: item.imageUrl,
      price: item.price,
      rating: item.rating,
      available: item.available,
    })),
  );
}));

app.get('/api/admin/menu', requireAdmin, asyncHandler(async (_, res) => {
  const menu = await prisma.menuItem.findMany({
    orderBy: [{ category: 'asc' }, { name: 'asc' }],
  });
  res.json(menu);
}));

app.post('/api/auth/send-otp', validateBody(otpSendSchema), asyncHandler(async (req, res) => {
  const phone = normalizePhone(req.body.phone);
  if (!/^[0-9]{10}$/.test(phone)) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'Phone must be 10 digits.');
  }

  const now = new Date();
  const existing = await prisma.oTP.findFirst({
    where: { phone },
    orderBy: { createdAt: 'desc' },
  });

  if (existing) {
    const notExpired = existing.expiresAt > now;
    if (notExpired && existing.resendCount >= 3) {
      throw new ApiError(429, 'OTP_LIMIT_REACHED', 'Maximum OTP resend limit reached. Try again later.');
    }
  }

  const otp = generateOtpCode();
  const expiresAt = new Date(Date.now() + 5 * 60 * 1000);
  const resendCount = existing && existing.expiresAt > now ? existing.resendCount + 1 : 1;

  await prisma.oTP.create({
    data: {
      phone,
      code: otp,
      expiresAt,
      resendCount,
      attempts: 0,
    },
  });

  // TODO: Replace console logging with SMS provider integration (MSG91/Fast2SMS/Twilio).
  console.log(`[OTP] ${phone}: ${otp}`);

  res.json({
    ok: true,
    message: 'OTP sent successfully.',
    expiresInSeconds: 300,
    ...(process.env.NODE_ENV === 'production' ? {} : { debugOtp: otp }),
  });
}));

app.post('/api/auth/verify-otp', validateBody(otpVerifySchema), asyncHandler(async (req, res) => {
  const phone = normalizePhone(req.body.phone);
  const otp = String(req.body.otp || '').trim();
  const now = new Date();

  const record = await prisma.oTP.findFirst({
    where: { phone },
    orderBy: { createdAt: 'desc' },
  });

  if (!record || record.expiresAt <= now) {
    throw new ApiError(400, 'OTP_EXPIRED', 'OTP expired or not found. Please resend.');
  }

  if (record.attempts >= 5) {
    throw new ApiError(429, 'OTP_ATTEMPTS_EXCEEDED', 'Too many invalid attempts. Please resend OTP.');
  }

  if (record.code !== otp) {
    await prisma.oTP.update({
      where: { id: record.id },
      data: { attempts: { increment: 1 } },
    });
    throw new ApiError(400, 'INVALID_OTP', 'Invalid OTP.');
  }

  await prisma.oTP.deleteMany({ where: { phone } });

  let user = await prisma.user.findFirst({ where: { phone } });
  if (!user) {
    user = await prisma.user.create({
      data: {
        name: `User ${phone.slice(-4)}`,
        phone,
        role: 'customer',
      },
    });
  }

  const token = signUserToken(user);
  res.json({
    token,
    user: toUserResponse(user),
  });
}));

app.post('/api/signup', validateBody(signupSchema), asyncHandler(async (req, res) => {
  const { name, email, phone, password } = req.body;
  const normalizedEmail = email.toLowerCase();
  const existing = await prisma.user.findUnique({ where: { email: normalizedEmail } });
  if (existing) {
    throw new ApiError(409, 'EMAIL_EXISTS', 'An account with this email already exists.');
  }

  const passwordHash = await bcrypt.hash(password, 10);
  const user = await prisma.user.create({
    data: {
      name,
      email: normalizedEmail,
      phone: phone || null,
      passwordHash,
      role: 'customer',
    },
  });
  const token = signUserToken(user);
  res.status(201).json({
    token,
    user: toUserResponse(user),
  });
}));

app.post('/api/login', validateBody(loginSchema), asyncHandler(async (req, res) => {
  const { email, password } = req.body;
  const normalizedEmail = email.toLowerCase();
  const user = await prisma.user.findUnique({ where: { email: normalizedEmail } });
  if (!user) {
    throw new ApiError(401, 'INVALID_CREDENTIALS', 'Invalid email or password.');
  }

  if (!user.passwordHash) {
    throw new ApiError(401, 'INVALID_CREDENTIALS', 'Use OTP login for this account.');
  }

  const isValid = await bcrypt.compare(password, user.passwordHash);
  if (!isValid) {
    throw new ApiError(401, 'INVALID_CREDENTIALS', 'Invalid email or password.');
  }

  const token = signUserToken(user);
  res.json({
    token,
    user: toUserResponse(user),
  });
}));

app.get('/api/me', requireAuth, asyncHandler(async (req, res) => {
  const userId = Number(req.user.sub);
  if (!Number.isInteger(userId) || userId <= 0) {
    throw new ApiError(401, 'UNAUTHORIZED', 'Invalid user token.');
  }
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) {
    throw new ApiError(404, 'NOT_FOUND', 'User not found.');
  }
  res.json(toUserResponse(user));
}));

app.post('/api/cart', validateBody(cartSchema), asyncHandler(async (req, res) => {
  const subtotal = req.body.items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
  const tax = Number((subtotal * 0.05).toFixed(2));
  const deliveryFee = subtotal >= 500 ? 0 : 30;
  const discount = 0;
  const total = Number((subtotal + tax + deliveryFee - discount).toFixed(2));
  res.json({
    items: req.body.items,
    pricing: { subtotal, tax, deliveryFee, discount, total },
  });
}));

app.post('/api/payment', validateBody(paymentSchema), asyncHandler(async (req, res) => {
  // Current phase uses mock payment response; real gateway integration is next.
  res.json({
    orderId: req.body.orderId,
    method: req.body.method,
    amount: req.body.amount,
    status: req.body.method === 'COD' ? 'pending_cod' : 'mock_success',
    transactionId: `TXN${Date.now()}`,
  });
}));

app.get('/api/menu/:id', asyncHandler(async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id <= 0) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'Menu id must be a positive integer.');
  }
  const item = await prisma.menuItem.findUnique({ where: { id } });
  const canViewUnavailable = (() => {
    const adminKey = process.env.ADMIN_API_KEY;
    const providedKey = req.headers['x-admin-key'];
    if (adminKey && providedKey === adminKey) return true;
    const payload = getOptionalAuthPayload(req);
    return String(payload?.role || '').toLowerCase() === 'admin';
  })();
  if (!item || (!item.available && !canViewUnavailable)) {
    throw new ApiError(404, 'NOT_FOUND', 'Menu item not found.');
  }
  res.json({
    id: item.id,
    name: item.name,
    category: item.category,
    type: item.type,
    ingredients: item.ingredients,
    imageUrl: item.imageUrl,
    price: item.price,
    rating: item.rating,
    available: item.available,
    createdAt: item.createdAt,
    updatedAt: item.updatedAt,
  });
}));

app.post('/api/admin/menu', requireAdmin, validateBody(menuItemCreateSchema), asyncHandler(async (req, res) => {
  const created = await prisma.menuItem.create({
    data: {
      ...req.body,
      imageUrl: req.body.imageUrl || '',
    },
  });
  res.status(201).json(created);
}));

app.put('/api/admin/menu/:id', requireAdmin, validateBody(menuItemUpdateSchema), asyncHandler(async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id <= 0) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'Menu id must be a positive integer.');
  }
  const updated = await prisma.menuItem.update({
    where: { id },
    data: req.body,
  });
  res.json(updated);
}));

app.delete('/api/admin/menu/:id', requireAdmin, asyncHandler(async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id <= 0) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'Menu id must be a positive integer.');
  }
  await prisma.menuItem.delete({ where: { id } });
  res.status(204).send();
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

  const first = await geocodeAddress(address);
  res.json(first);
}));

app.get('/api/reverse-geocode', asyncHandler(async (req, res) => {
  const latitude = Number(req.query.lat);
  const longitude = Number(req.query.lng);
  if (Number.isNaN(latitude) || Number.isNaN(longitude)) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'lat and lng are required numeric query params.');
  }

  const resolved = await reverseGeocode(latitude, longitude);
  res.json({
    latitude,
    longitude,
    label: resolved.label,
  });
}));

app.get('/api/orders', requireAdmin, asyncHandler(async (_, res) => {
  const orders = await prisma.order.findMany({
    include: { items: true },
    orderBy: { createdAt: 'desc' },
  });

  res.json(orders.map((order) => toOrderResponse(order)));
}));

app.get('/api/admin/orders', requireAdmin, asyncHandler(async (_, res) => {
  const orders = await prisma.order.findMany({
    include: { items: true },
    orderBy: { createdAt: 'desc' },
  });
  res.json(orders);
}));

app.get('/api/orders/:id', asyncHandler(async (req, res) => {
  const order = await prisma.order.findUnique({
    where: { id: req.params.id },
    include: { items: true },
  });
  if (!order) {
    throw new ApiError(404, 'NOT_FOUND', 'Order not found.');
  }

  const adminKey = process.env.ADMIN_API_KEY;
  const providedKey = req.headers['x-admin-key'];
  const authPayload = getOptionalAuthPayload(req);
  const isAdmin = (adminKey && providedKey === adminKey)
    || String(authPayload?.role || '').toLowerCase() === 'admin';

  if (!isAdmin) {
    if (!authPayload || !authPayload.sub) {
      throw new ApiError(401, 'UNAUTHORIZED', 'Missing auth token');
    }
    if (!order.userId || Number(authPayload.sub) !== order.userId) {
      throw new ApiError(403, 'FORBIDDEN', 'Access denied for this order.');
    }
  }

  res.json(toOrderResponse(order));
}));

app.get('/api/my/orders', requireAuth, asyncHandler(async (req, res) => {
  const userId = Number(req.user.sub);
  if (!Number.isInteger(userId) || userId <= 0) {
    throw new ApiError(401, 'UNAUTHORIZED', 'Invalid user token.');
  }
  const orders = await prisma.order.findMany({
    where: { userId },
    include: { items: true },
    orderBy: { createdAt: 'desc' },
  });
  res.json(orders);
}));

app.get('/api/my/orders/:id', requireAuth, asyncHandler(async (req, res) => {
  const userId = Number(req.user.sub);
  if (!Number.isInteger(userId) || userId <= 0) {
    throw new ApiError(401, 'UNAUTHORIZED', 'Invalid user token.');
  }
  const order = await prisma.order.findFirst({
    where: { id: req.params.id, userId },
    include: { items: true },
  });
  if (!order) {
    throw new ApiError(404, 'NOT_FOUND', 'Order not found.');
  }
  res.json(order);
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
  const userId = getOptionalUserIdFromRequest(req);

  const created = await prisma.order.create({
    data: {
      ...orderPayload,
      userId,
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

  const response = toOrderResponse(created);
  broadcastOrderEvent({ type: 'order:new', order: response });
  return res.status(201).json(response);
}));

app.patch('/api/orders/:id/status', requireAdmin, validateBody(orderStatusSchema), asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;
  const updated = await prisma.order.update({
    where: { id },
    data: { status },
    include: { items: true },
  });
  const response = {
    id: updated.id,
    status: updated.status,
    createdAt: updated.createdAt,
  };
  broadcastOrderEvent({
    type: 'order:update',
    order: toOrderResponse(updated),
  });
  res.json(response);
}));

app.patch('/api/admin/order-status', requireAdmin, validateBody(adminOrderStatusSchema), asyncHandler(async (req, res) => {
  const updated = await prisma.order.update({
    where: { id: req.body.orderId },
    data: { status: req.body.status },
    include: { items: true },
  });
  res.json(updated);
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
    const server = app.listen(PORT, () => {
      console.log(`Papichulo backend running on http://localhost:${PORT}`);
    });

    const wss = new WebSocketServer({
      server,
      path: '/ws/orders',
    });

    wss.on('connection', (socket, req) => {
      if (!isAdminWebSocketRequest(req.url)) {
        socket.close(1008, 'Admin access required');
        return;
      }

      wsAdminClients.add(socket);
      socket.send(
        JSON.stringify({
          type: 'connected',
          message: 'admin-order-stream-ready',
          timestamp: new Date().toISOString(),
        }),
      );

      socket.on('close', () => {
        wsAdminClients.delete(socket);
      });
      socket.on('error', () => {
        wsAdminClients.delete(socket);
      });
    });
  } catch (error) {
    console.error('Failed to start backend:', error.message);
    process.exit(1);
  }
}

start();
