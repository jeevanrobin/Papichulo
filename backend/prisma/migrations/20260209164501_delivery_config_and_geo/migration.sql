-- AlterTable
ALTER TABLE "Order" ADD COLUMN "latitude" REAL;
ALTER TABLE "Order" ADD COLUMN "longitude" REAL;

-- CreateTable
CREATE TABLE "DeliveryConfig" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "storeLatitude" REAL NOT NULL,
    "storeLongitude" REAL NOT NULL,
    "radiusKm" REAL NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);
