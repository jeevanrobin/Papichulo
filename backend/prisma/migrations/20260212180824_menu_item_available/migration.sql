-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_MenuItem" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "name" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "ingredients" JSONB NOT NULL,
    "imageUrl" TEXT NOT NULL,
    "price" REAL NOT NULL,
    "rating" REAL NOT NULL,
    "available" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);
INSERT INTO "new_MenuItem" ("category", "createdAt", "id", "imageUrl", "ingredients", "name", "price", "rating", "type", "updatedAt") SELECT "category", "createdAt", "id", "imageUrl", "ingredients", "name", "price", "rating", "type", "updatedAt" FROM "MenuItem";
DROP TABLE "MenuItem";
ALTER TABLE "new_MenuItem" RENAME TO "MenuItem";
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
