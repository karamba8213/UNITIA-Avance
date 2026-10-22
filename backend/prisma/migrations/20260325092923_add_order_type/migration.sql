-- CreateEnum
CREATE TYPE "OrderType" AS ENUM ('DELIVERY', 'PICKUP');

-- AlterTable
ALTER TABLE "Order" ADD COLUMN     "orderType" "OrderType" NOT NULL DEFAULT 'DELIVERY';
