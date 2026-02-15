const { PrismaClient } = require('@prisma/client');
const fs = require('fs');
const path = require('path');

const prisma = new PrismaClient();

async function main() {
  await prisma.deliveryConfig.upsert({
    where: { id: 1 },
    update: {},
    create: {
      id: 1,
      storeLatitude: 17.385044,
      storeLongitude: 78.486671,
      radiusKm: 10,
    },
  });

  const menuPath = path.join(__dirname, '..', 'data', 'menu.json');
  const raw = fs.readFileSync(menuPath, 'utf8');
  const menu = JSON.parse(raw);
  const existing = await prisma.menuItem.findMany();
  const existingByName = new Map(existing.map((item) => [item.name, item]));

  let added = 0;
  let updated = 0;

  for (const rawItem of menu) {
    const item = {
      name: String(rawItem.name || ''),
      category: String(rawItem.category || ''),
      type: String(rawItem.type || ''),
      ingredients: Array.isArray(rawItem.ingredients) ? rawItem.ingredients : [],
      imageUrl: String(rawItem.imageUrl || ''),
      price: Number(rawItem.price || 0),
      rating: Number(rawItem.rating || 0),
      available:
        typeof rawItem.available === 'boolean' ? rawItem.available : true,
    };

    const current = existingByName.get(item.name);
    if (!current) {
      await prisma.menuItem.create({ data: item });
      added += 1;
      continue;
    }

    const hasChanged =
      current.category !== item.category ||
      current.type !== item.type ||
      JSON.stringify(current.ingredients) !== JSON.stringify(item.ingredients) ||
      current.imageUrl !== item.imageUrl ||
      current.price !== item.price ||
      current.rating !== item.rating ||
      current.available !== item.available;

    if (hasChanged) {
      await prisma.menuItem.update({
        where: { id: current.id },
        data: {
          category: item.category,
          type: item.type,
          ingredients: item.ingredients,
          imageUrl: item.imageUrl,
          price: item.price,
          rating: item.rating,
          available: item.available,
        },
      });
      updated += 1;
    }
  }

  console.log(
    `Menu sync complete. Existing: ${existing.length}, added: ${added}, updated: ${updated}, total source: ${menu.length}`,
  );
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
