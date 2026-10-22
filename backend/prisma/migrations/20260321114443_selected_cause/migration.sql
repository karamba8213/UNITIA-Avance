/*
  Warnings:

  - You are about to drop the column `favoriteCauseId` on the `Customer` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "Customer" DROP COLUMN "favoriteCauseId",
ADD COLUMN     "selectedCauseAt" TIMESTAMP(3),
ADD COLUMN     "selectedCauseId" TEXT;
