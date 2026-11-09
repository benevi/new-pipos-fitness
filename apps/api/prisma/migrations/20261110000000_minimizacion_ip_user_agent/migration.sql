-- Minimización (RGPD art. 5.1.c): no se guarda IP ni user-agent en el consentimiento
-- (la prueba es el evento autenticado + versión + hash del texto mostrado) ni en los
-- refresh tokens (esas columnas nunca se rellenaban).

-- AlterTable
ALTER TABLE "ConsentEvent" DROP COLUMN "ip",
DROP COLUMN "userAgent";

-- AlterTable
ALTER TABLE "RefreshToken" DROP COLUMN "createdByIp",
DROP COLUMN "userAgent";
