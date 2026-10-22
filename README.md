# Unitia

Plataforma que conecta restaurantes con causas sociales. Cada pedido genera una donación automática.

## Stack

| Capa | Tecnología |
|------|-----------|
| Backend | Node.js + Express + Prisma |
| Base de datos | PostgreSQL 15 |
| Frontend | Next.js 14 + Tailwind CSS |
| Auth | NextAuth (Google, Apple, Email/Password) |
| Local dev | Docker Compose |

## Inicio rápido

### 0. Recuperar las credenciales locales (Windows)

El respaldo de esta PC está en `C:\unitia-credenciales-locales`. Los valores secretos
no se guardan en GitHub. Después de clonar el repositorio, ejecutar desde su raíz:

```powershell
.\scripts\restore-local-credentials.ps1
```

Esto restaura `backend/.env`, `frontend/.env.local`, `firebase-admin.json` y las
configuraciones de Firebase de Android e iOS a las rutas que usa el proyecto.
Los archivos existentes se conservan y los restaurados siguen excluidos de Git.
Para comprobar el respaldo sin copiar, agregar `-CheckOnly`. En otra computadora,
copiar primero el respaldo y usar `-CredentialsRoot 'RUTA_DEL_RESPALDO'` si cambia
su ubicación. No reemplazar los `.env` restaurados con las plantillas de ejemplo
de los pasos siguientes; esas plantillas se usan cuando no hay credenciales.

### 1. Base de datos (Docker)
```bash
docker-compose up -d
```

### 2. Backend
```bash
cd backend
cp .env.example .env        # completar variables
npm install
npx prisma migrate dev      # crea tablas
npm run dev                 # corre en :4000
```

### 3. Frontend
```bash
cd frontend
cp .env.example .env.local  # completar variables
npm install
npm run dev                 # corre en :3000
```

## Variables de entorno requeridas

### backend/.env
```
DATABASE_URL=postgresql://unitia:unitia@localhost:5432/unitia_db
JWT_SECRET=...
JWT_REFRESH_SECRET=...
```

### frontend/.env.local
```
NEXT_PUBLIC_API_URL=http://localhost:4000/api/v1
NEXTAUTH_SECRET=...
GOOGLE_CLIENT_ID=...         # de Google Cloud Console
GOOGLE_CLIENT_SECRET=...
APPLE_ID=...                 # de Apple Developer
APPLE_TEAM_ID=...
APPLE_PRIVATE_KEY=...
APPLE_KEY_ID=...
```

## URLs locales

| URL | Descripción |
|-----|-------------|
| `http://localhost:3000` | Landing page |
| `http://localhost:3000/login` | Login (Google, Apple, email) |
| `http://localhost:3000/register` | Registro |
| `http://localhost:3000/restaurant/dashboard` | Dashboard restaurante |
| `http://localhost:3000/cause/dashboard` | Dashboard causa |
| `http://localhost:3000/c/[slug]` | Página pública de causa |
| `http://localhost:3000/r/[slug]` | Página de pedido de restaurante |
| `http://localhost:3000/mi-impacto` | Impacto del cliente por email |
| `http://localhost:4000/health` | API health check |
| `http://localhost:4000/api/v1/...` | API REST |

## Estructura del proyecto

```
unitia/
  agents/          # Roles del equipo de desarrollo (PM, Backend, Frontend, DB, DevOps, QA)
  backend/         # API Node.js + Express + Prisma
    prisma/        # Schema y migraciones
    src/
      config/      # Prisma client
      middleware/  # Auth JWT, error handler
      routes/      # auth, restaurants, causes, orders, donations, public
      services/    # Lógica de negocio
  docs/            # Documentación técnica
  frontend/        # Next.js 14 App Router
    src/app/       # Páginas
    src/components/# Componentes reutilizables
    src/lib/       # API client, auth helpers
  docker-compose.yml
  UNITIA_SYSTEM_PROMPT.md  # Visión del producto
```

## Flujo de donación

```
Cliente ordena → Order + OrderItem creados (atómico)
              → Donation PENDING creada (monto calculado server-side)
              → Restaurante ve en dashboard: "Tenés $X pendiente para [Causa]"
              → Restaurante marca como PAID
              → Causa ve notificación: "$X recibido de [Restaurante]"
              → Causa confirma → CONFIRMED
              → Página pública de causa actualiza total recaudado
```

## Tracking de impacto del cliente

En `/mi-impacto`, cualquier cliente puede ingresar su email y ver:
- Total donado en todos sus pedidos
- Breakdown por causa (cuánto fue a cada una)
- Historial de pedidos con monto y causa

## Login con OAuth

El login soporta:
1. **Google** — via NextAuth GoogleProvider
2. **Apple** — via NextAuth AppleProvider
3. **Email + contraseña** — via CredentialsProvider

Los usuarios OAuth nuevos son creados automáticamente en el backend via `/api/v1/auth/oauth`.
