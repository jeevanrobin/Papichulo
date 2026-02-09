const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3001;
const dataDir = path.join(__dirname, 'data');
const ordersPath = path.join(dataDir, 'orders.json');
const menuPath = path.join(dataDir, 'menu.json');

function ensureDataFiles() {
  if (!fs.existsSync(dataDir)) fs.mkdirSync(dataDir, { recursive: true });
  if (!fs.existsSync(ordersPath)) fs.writeFileSync(ordersPath, '[]');
  if (!fs.existsSync(menuPath)) fs.writeFileSync(menuPath, '[]');
}

function readJson(filePath, fallback) {
  try {
    const raw = fs.readFileSync(filePath, 'utf8');
    return JSON.parse(raw);
  } catch (_) {
    return fallback;
  }
}

function writeJson(filePath, value) {
  fs.writeFileSync(filePath, JSON.stringify(value, null, 2));
}

function makeOrderId() {
  const ts = Date.now().toString().slice(-8);
  const random = Math.floor(1000 + Math.random() * 9000);
  return `ORD${ts}${random}`;
}

ensureDataFiles();

app.use(cors());
app.use(express.json());

app.get('/health', (_, res) => {
  res.json({ ok: true, service: 'papichulo-backend' });
});

app.get('/api/menu', (_, res) => {
  const menu = readJson(menuPath, []);
  res.json(menu);
});

app.get('/api/orders', (_, res) => {
  const orders = readJson(ordersPath, []);
  orders.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
  res.json(orders);
});

app.post('/api/orders', (req, res) => {
  const { customerName, phone, address, paymentMethod, items, totalAmount } = req.body || {};

  if (!customerName || !phone || !address || !paymentMethod || !Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ error: 'Invalid order payload' });
  }

  const order = {
    id: makeOrderId(),
    customerName: String(customerName).trim(),
    phone: String(phone).trim(),
    address: String(address).trim(),
    paymentMethod: String(paymentMethod).trim(),
    items: items.map((item) => ({
      name: String(item.name || ''),
      price: Number(item.price || 0),
      quantity: Number(item.quantity || 0),
    })),
    totalAmount: Number(totalAmount || 0),
    status: 'new',
    createdAt: new Date().toISOString(),
  };

  const orders = readJson(ordersPath, []);
  orders.push(order);
  writeJson(ordersPath, orders);

  return res.status(201).json(order);
});

app.listen(PORT, () => {
  console.log(`Papichulo backend running on http://localhost:${PORT}`);
});
