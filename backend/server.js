const express = require('express');
const cors = require('cors');
const { PrismaClient } = require('@prisma/client');

const app = express();
const PORT = process.env.PORT || 3001;
const prisma = new PrismaClient();
const asyncHandler = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

function makeOrderId() {
  const ts = Date.now().toString().slice(-8);
  const random = Math.floor(1000 + Math.random() * 9000);
  return `ORD${ts}${random}`;
}

app.use(cors());
app.use(express.json());

app.get('/health', asyncHandler(async (_, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.json({ ok: true, service: 'papichulo-backend', db: 'connected' });
  } catch (_) {
    res.status(500).json({ ok: false, service: 'papichulo-backend', db: 'disconnected' });
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

app.get('/api/orders', asyncHandler(async (_, res) => {
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

app.post('/api/orders', asyncHandler(async (req, res) => {
  const { customerName, phone, address, paymentMethod, items, totalAmount } = req.body || {};

  if (!customerName || !phone || !address || !paymentMethod || !Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ error: 'Invalid order payload' });
  }

  const orderPayload = {
    id: makeOrderId(),
    customerName: String(customerName).trim(),
    phone: String(phone).trim(),
    address: String(address).trim(),
    paymentMethod: String(paymentMethod).trim(),
    totalAmount: Number(totalAmount || 0),
    status: 'new'
  };

  const created = await prisma.order.create({
    data: {
      ...orderPayload,
      items: {
        create: items.map((item) => ({
          name: String(item.name || ''),
          price: Number(item.price || 0),
          quantity: Number(item.quantity || 0),
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

app.use((error, _, res, __) => {
  console.error('API error:', error);
  res.status(500).json({ error: 'Internal server error' });
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
