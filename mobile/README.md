# Unitia Mobile

App para Android e iOS construida con Expo (React Native).
Usa el mismo backend en `/backend`.

## Instalar y correr localmente

```bash
cd mobile
npm install
npx expo start
```

Después escaneás el QR con **Expo Go** (iOS/Android) para ver la app en tu celular.

## Variables de entorno

Crear `.env.local` en `/mobile`:
```
EXPO_PUBLIC_API_URL=http://TU_IP_LOCAL:4000/api/v1
```

> En desarrollo usá tu IP de red local (no localhost), ej: `192.168.1.100:4000`
> Para producción: la URL de Railway/Render donde tenés el backend.

## Publicar en Play Store y App Store

### Requisitos previos
1. Cuenta en [Expo](https://expo.dev) (gratis)
2. Cuenta en [Google Play Console](https://play.google.com/console) (u$s 25 único pago)
3. Cuenta en [Apple Developer Program](https://developer.apple.com) (u$s 99/año)

### Paso 1 — Instalar EAS CLI
```bash
npm install -g eas-cli
eas login
```

### Paso 2 — Configurar el proyecto
```bash
cd mobile
eas build:configure
```

### Paso 3 — Build de producción

**Android (Play Store):**
```bash
eas build --platform android --profile production
```
Genera un `.aab` (Android App Bundle) listo para subir a Play Store.

**iOS (App Store):**
```bash
eas build --platform ios --profile production
```
Requiere cuenta Apple Developer activa. EAS maneja los certificates automáticamente.

**Ambas plataformas a la vez:**
```bash
eas build --platform all --profile production
```

### Paso 4 — Subir a las tiendas

**Android → Play Store:**
```bash
eas submit --platform android
```
O descargás el `.aab` y lo subís manualmente en [Play Console](https://play.google.com/console).

**iOS → App Store:**
```bash
eas submit --platform ios
```
Configurar en `eas.json`:
- `appleId`: tu Apple ID
- `ascAppId`: ID de la app en App Store Connect
- `appleTeamId`: tu Team ID de Apple Developer

### Paso 5 — Actualizar sin rebuild (OTA)

Para actualizaciones de JS (sin cambios nativos):
```bash
eas update --branch production --message "descripcion del cambio"
```
Los usuarios reciben la actualización automáticamente.

## Estructura de pantallas

```
app/
  index.tsx                → Redirect automático según rol
  (auth)/
    login.tsx              → Login con email/contraseña
    register.tsx           → Registro (restaurante o causa)
  (restaurant)/
    dashboard.tsx          → Panel principal del restaurante
    orders.tsx             → Historial de pedidos
    donations.tsx          → Donaciones (marcar como pagadas)
    menu.tsx               → Gestión de menú
    settings.tsx           → Ajustes del perfil
  (cause)/
    dashboard.tsx          → Panel principal de la causa
    settings.tsx           → Ajustes del perfil
  (customer)/
    impacto.tsx            → Buscar impacto por email
```

## App ID (cambiar antes de publicar)

En `app.json`:
- iOS: `bundleIdentifier: "com.unitia.app"`
- Android: `package: "com.unitia.app"`

Cambiar a un identificador único tuyo, ej: `com.miempresa.unitia`

## Íconos y splash screen

Reemplazar los archivos en `/assets/`:
- `icon.png` — 1024×1024px, fondo sólido
- `adaptive-icon.png` — 1024×1024px (Android)
- `splash.png` — 1284×2778px mínimo
- `favicon.png` — 48×48px (web)

Usar herramientas como [EAS Asset Generator](https://docs.expo.dev/develop/user-interface/splash-screen/)
o [Icon Kitchen](https://icon.kitchen).
