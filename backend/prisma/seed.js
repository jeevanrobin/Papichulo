const { PrismaClient } = require('@prisma/client');
const fs = require('fs');
const path = require('path');

const prisma = new PrismaClient();

async function main() {
  const count = await prisma.menuItem.count();
  if (count > 0) {
    console.log('Menu already seeded');
    return;
  }

  const menuPath = path.join(__dirname, '..', 'data', 'menu.json');
  const raw = fs.readFileSync(menuPath, 'utf8');
  const menu = JSON.parse(raw);

  await prisma.menuItem.createMany({
    data: menu.map((item) => ({
      name: String(item.name || ''),
      category: String(item.category || ''),
      type: String(item.type || ''),
      ingredients: Array.isArray(item.ingredients) ? item.ingredients : [],
      imageUrl: String(item.imageUrl || ''),
      price: Number(item.price || 0),
      rating: Number(item.rating || 0),
    })),
  });

  console.log(`Seeded ${menu.length} menu items`);
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
