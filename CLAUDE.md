# Unitia — Guía para Claude Code

## ¿Qué es Unitia?

Plataforma que conecta restaurantes con causas sociales. Cada pedido en un restaurante participante genera una donación automática a la causa que el restaurante eligió apoyar.

**Flujo central:**
1. Restaurante se registra → elige una causa → setea % de donación (default 5%)
2. Cliente hace un pedido → se crea un `order` + `donation` atómicamente en Firestore
3. Restaurante marca la donación como pagada → causa la confirma
4. La página pública de la causa muestra el progreso en tiempo real

---

## Estructura del monorepo

```
unitia/
  unitia_app/     ← App Flutter (PRINCIPAL, producción activa)
  mobile/         ← App Expo/React Native (secundaria / en paralelo)
  backend/        ← API Node.js + Express + Prisma + PostgreSQL
  frontend/       ← Web Next.js 14 (landing + dashboards web)
  agents/         ← Roles del equipo (PM, Backend, Frontend, etc.)
  docs/           ← Documentación técnica (actualmente vacío)
  scripts/        ← Scripts utilitarios (Firebase Admin SDK, etc.)
  firebase-admin.json  ← Service account de Firebase (NO commitear)
  firestore.indexes.json  ← Índices compuestos de Firestore
  firestore.rules         ← Reglas de seguridad de Firestore
  firebase.json           ← Config Firebase CLI
```

---

## App principal: `unitia_app/` (Flutter)

### Correr
```bash
cd unitia_app
flutter run                # elige dispositivo interactivo
flutter run -d chrome      # web
flutter run -d emulator-id # emulador Android
flutter devices            # lista dispositivos disponibles
```

### Stack
- **Flutter** + **Firebase** (Auth, Firestore, Storage)
- **Provider** para estado
- **google_sign_in** + **sign_in_with_apple** para OAuth

### Estructura `lib/`
```
lib/
  main.dart
  firebase_options.dart
  core/
    models/        app_user.dart, restaurant.dart, cause.dart, order.dart
    providers/     auth_provider.dart
    services/      auth_service.dart, firestore_service.dart
    theme/         app_theme.dart
  screens/
    auth/          login_screen.dart, register_screen.dart
    restaurant/    restaurant_home.dart, restaurant_orders_screen.dart,
                   restaurant_donations_screen.dart, restaurant_menu_screen.dart,
                   restaurant_settings_screen.dart
    cause/         cause_home.dart, cause_donations_screen.dart,
                   cause_settings_screen.dart
  widgets/common/  app_button.dart, app_input.dart, donation_badge.dart, stat_card.dart
```

### Archivo clave: `firestore_service.dart`
Toda la lógica de Firestore está centralizada aquí. Contiene:
- CRUD de restaurantes y causas
- Streams en tiempo real para orders y donations
- Creación atómica de order + donation (batch)
- `markDonationPaid` y `confirmDonationReceived`
- Dashboard stats para restaurante y causa
- `getCustomerImpact` por email

---

## Estructura Firestore

### Colecciones principales

| Colección | Doc ID | Notas |
|-----------|--------|-------|
| `users` | Firebase Auth UID | Rol: `restaurant` o `cause` |
| `restaurants` | Firebase Auth UID del dueño | |
| `restaurants/{id}/menu` | Auto | Subcollección de items |
| `causes` | Firebase Auth UID del dueño | |
| `orders` | Auto | Items embebidos como array |
| `donations` | **Mismo ID que la order** | 1-a-1 con cada order |

### Campos clave denormalizados (para evitar joins)
- `orders` y `donations` guardan `restaurantName` y `causeName`
- `donations` también guarda `customerName`
- `causes` tiene `totalRaised` actualizado con `FieldValue.increment` al confirmar

### Statuses
- **orders.status**: `pending` | `confirmed` | `cancelled`
- **orders.donationStatus**: `pending` | `paid` | `confirmed` | `disputed`
- **donations.status**: `pending` | `paid` | `confirmed` | `disputed`

---

## Proyecto Firebase

- **Project ID**: `unitia-57f59`
- **Service account**: `firebase-admin.json` en raíz del repo

### Problema conocido: Google Sign-In
El `google-services.json` actual solo tiene el cliente Android (`client_type: 3`).
Para que Google Sign-In funcione se necesita también el web client (`client_type: 2`).

**Fix:**
1. Firebase Console → Authentication → Sign-in method → Habilitar Google
2. Project Settings → App Android → Agregar SHA-1 del certificado debug:
   ```bash
   cd unitia_app/android && ./gradlew signingReport
   ```
3. Re-descargar `google-services.json` y reemplazar `unitia_app/android/app/google-services.json`
4. `flutter clean && flutter run`

---

## Backend: `backend/` (Node.js + Express + Prisma)

### Correr
```bash
cd backend
cp .env.example .env   # completar DATABASE_URL, JWT_SECRET, JWT_REFRESH_SECRET
npm install
npx prisma migrate dev
npm run dev            # corre en :4000
```

### Stack
- Node.js + Express + Prisma + PostgreSQL 15
- JWT con refresh tokens
- API REST en `/api/v1`

### Rutas: `src/routes/`
- `auth` — registro, login, OAuth
- `restaurants` — CRUD restaurantes
- `causes` — CRUD causas
- `orders` — crear pedidos
- `donations` — marcar pagado / confirmar
- `public` — páginas públicas sin auth

### Base de datos local
```bash
docker-compose up -d   # levanta PostgreSQL en :5432
```

---

## Frontend web: `frontend/` (Next.js 14)

### Correr
```bash
cd frontend
cp .env.example .env.local
npm install
npm run dev   # corre en :3000
```

### Rutas importantes
- `/` — Landing
- `/login`, `/register` — Auth (Google, Apple, email)
- `/restaurant/dashboard` — Dashboard restaurante
- `/cause/dashboard` — Dashboard causa
- `/c/[slug]` — Página pública causa
- `/r/[slug]` — Página de pedido de restaurante
- `/mi-impacto` — Impacto del cliente por email

---

## App mobile Expo: `mobile/` (secundaria)

```bash
cd mobile
npm install
npx expo start
```

---

## Scripts utilitarios

```bash
# Setup/seed Firestore (Admin SDK)
cd scripts
node firestore-setup.js          # solo estructura
node firestore-setup.js --seed   # también datos demo
```

---

## Convenciones

- Doc IDs de `restaurants` y `causes` = **Firebase Auth UID** del usuario dueño
- Doc ID de `donations` = **mismo ID** que la `order` correspondiente
- Siempre crear `order` + `donation` en un **batch atómico**
- Agregar solo campos necesarios al modelo — no over-engineer
- Los agregados (`totalRaised`, etc.) se actualizan con `FieldValue.increment`, nunca recalculando
