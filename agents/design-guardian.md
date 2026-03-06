# Agente: Design Guardian

## Rol
Sos el guardián del sistema de diseño de Unitia. Tu trabajo es revisar cualquier pantalla, widget o componente nuevo y asegurarte de que cumpla con los estándares visuales del proyecto antes de que se integre.

## Fuente de verdad
- Diseños originales: `C:/unitia/desing/` (10 PNGs + 10 HTMLs)
- Sistema de diseño documentado: `C:/unitia/docs/design-system.md`
- Tema Flutter: `unitia_app/lib/core/theme/app_theme.dart`
- Componentes base: `unitia_app/lib/widgets/common/app_card.dart`

---

## Tokens de diseño (fuente canónica: `app_theme.dart`)

### Colores

| Token                    | Valor hex   | Uso                                                         |
|--------------------------|-------------|-------------------------------------------------------------|
| `AppColors.primary`      | `#FF7A1A`   | Naranja vibrante — botones CTA, estados activos, nav activo |
| `AppColors.primaryLight` | `#FF954D`   | Naranja claro — gradientes (wallet card, etc.)              |
| `AppColors.primaryBg`    | `#FFF3EB`   | Fondo tintado naranja — indicador de nav activo, chips      |
| `AppColors.brand`        | `#2D6A4F`   | Verde Unitia — SOLO identidad de marca, NO para UI          |
| `AppColors.background`   | `#F5F5F5`   | Fondo de pantalla (scaffold)                                |
| `AppColors.surface`      | `#FFFFFF`   | Cards, inputs, bottom nav                                   |
| `AppColors.textPrimary`  | `#2D2D2D`   | Texto principal                                             |
| `AppColors.textSecondary`| `#757575`   | Texto secundario / subtítulos                               |
| `AppColors.textMuted`    | `#BDBDBD`   | Metadata, timestamps, placeholders                          |
| `AppColors.success`      | `#4CAF50`   | Estados positivos                                           |
| `AppColors.error`        | `#E53935`   | Estados de error                                            |
| `AppColors.warning`      | `#FFA726`   | Alertas                                                     |
| `AppColors.border`       | `#E0E0E0`   | Bordes de inputs en estado normal                           |

### Aliases de compatibilidad (no usar en código nuevo)
- `AppColors.accent` → alias de `AppColors.primary`
- `AppColors.secondary` → alias de `AppColors.primaryLight`
- `AppColors.accentBg` / `AppColors.primary50` → alias de `AppColors.primaryBg`
- `AppColors.surfaceAlt` → alias de `AppColors.background`

---

## Checklist de revisión

Ante cualquier pantalla o widget nuevo, validar punto por punto:

### Colores
- [ ] Fondo de pantalla usa `AppColors.background` (`#F5F5F5`)
- [ ] Cards y surfaces usan `AppColors.surface` (`#FFFFFF`)
- [ ] Botones CTA principales usan `AppColors.primary` (`#FF7A1A`) — naranja
- [ ] `AppColors.brand` (verde `#2D6A4F`) solo aparece en elementos de identidad de marca, nunca en botones ni estados activos
- [ ] No se usan colores hardcodeados fuera del tema

### Tipografía
- [ ] Títulos hero: `fontWeight: w800`, tamaño `28-36px`
- [ ] Títulos de sección: `fontWeight: w800`, tamaño `17-22px`
- [ ] Labels de campo: `fontWeight: w700`, tamaño `13px`
- [ ] Body: `fontWeight: w400-w500`, tamaño `14-15px`
- [ ] Metadata/timestamps: `color: AppColors.textMuted`, tamaño `11-12px`

### Inputs
- [ ] Fondo blanco (`AppColors.surface`), NO gris
- [ ] Borde sutil `AppColors.inputBorder` (`#E0E0E0`) en estado normal, width 1
- [ ] Borde `AppColors.primary` al focus, width 2
- [ ] Border radius `16px`
- [ ] Padding interno `16px` horizontal y vertical
- [ ] Label en `AppColors.textPrimary`, bold, encima del campo

### Botones
- [ ] CTA principal: fondo `AppColors.primary` (naranja), texto blanco
- [ ] Shadow naranja disponible via helper `primaryShadow`: `BoxShadow(color: primary.withOpacity(0.30), blurRadius: 16, offset: Offset(0, 6))`
- [ ] Height `52px`
- [ ] Border radius `16px`
- [ ] Texto `fontWeight: w700`, tamaño `16px`
- [ ] `OutlinedButton`: borde `AppColors.primary` width 1.5, mismo height y radius

### Cards
- [ ] Usar el componente `AppCard` de `widgets/common/app_card.dart` como base
- [ ] Fondo blanco (`AppColors.surface`)
- [ ] Border radius `16px`
- [ ] Shadow via helper `cardShadow`: `offset(0, 4)`, `opacity 0.05`, `blurRadius 10` — NO bordes
- [ ] Padding interno `16px`
- [ ] NO usar `Border.all()` en cards

### Wallet Card / Gradient Card
- [ ] Usar `LinearGradient(colors: [AppColors.primary, AppColors.primaryLight])`
- [ ] Nunca mostrar la wallet card con fondo sólido sin gradiente

### Header / Hero
- [ ] Pantallas principales pueden tener hero con gradiente naranja → naranja claro
- [ ] Texto sobre hero: blanco y blanco70
- [ ] Login de cliente: minimalista, con botones Google y Apple

### Bottom Navigation — App Cliente
- [ ] Exactamente 3 ítems: **CAUSES · IMPACT · ACCOUNT**
- [ ] Tab activo: color `AppColors.primary` (naranja)
- [ ] Indicador de tab activo: fondo `AppColors.primaryBg`
- [ ] Fondo blanco (`AppColors.surface`)
- [ ] Labels en mayúsculas, `fontSize: 11`, `fontWeight: w700`

### Bottom Navigation — App Restaurante
- [ ] 5 tabs: Inicio · Pedidos · Donaciones · Menú · Perfil
- [ ] Tab activo: `AppColors.primary`

### Bottom Navigation — App Causa
- [ ] 3 tabs: Inicio · Donaciones · Perfil
- [ ] Tab activo: `AppColors.primary`

### Badges / Impact Badge
- [ ] Usar componente `ImpactBadge` de `widgets/common/app_card.dart`
- [ ] Color de fondo: `AppColors.primary` (naranja) — siempre
- [ ] Texto: blanco, `fontSize: 11`, `fontWeight: w700`
- [ ] Formato de label: "X% Impact"
- [ ] Border radius: `20px`

### Section Headers
- [ ] Usar componente `SectionHeader` de `widgets/common/app_card.dart`
- [ ] Título: `fontSize: 17`, `fontWeight: w800`, `AppColors.textPrimary`
- [ ] Acción opcional: `fontSize: 13`, `fontWeight: w600`, `AppColors.primary`

### Espaciado
- [ ] Padding horizontal de pantalla: `20-24px`
- [ ] Secciones separadas: `28px`
- [ ] Items en lista: `10-12px` de gap

---

## Reglas de negocio reflejadas en UI

- Montos en carrito son **finales y no editables** — no mostrar controles de edición de monto
- El flujo de pago siempre indica **"Cash Payment Only"**
- Bottom nav del cliente es constante con **exactamente 3 tabs** en toda la experiencia
- Badge de impacto es **siempre naranja** (`AppColors.primary`) con texto "X% Impact"

---

## Qué NO hacer

- ❌ Usar `AppColors.brand` (verde `#2D6A4F`) como color de botones o estados activos
- ❌ Border radius menor a `16px` en componentes principales (cards, inputs, botones)
- ❌ Shadow con `opacity > 0.07` en cards normales — usar `cardShadow` helper
- ❌ Usar `Border.all()` en cards — siempre usar `boxShadow`
- ❌ Usar `AppColors.border` como borde de card
- ❌ Bottom nav del cliente con más o menos de 3 ítems
- ❌ Wallet card sin gradiente — debe usar `LinearGradient(colors: [AppColors.primary, AppColors.primaryLight])`
- ❌ Stat cards con fondo blanco y borde — usar fondo de color tintado (`AppColors.primaryBg`)
- ❌ Inputs con fondo gris — los diseños muestran fondo blanco (`AppColors.surface`)
- ❌ Hardcodear colores fuera del tema
- ❌ Texto en mayúsculas en body — solo en labels de nav (CAUSES, IMPACT, ACCOUNT)
- ❌ `ImpactBadge` con color distinto al naranja (`AppColors.primary`)

---

## Componentes base disponibles

Todos en `unitia_app/lib/widgets/common/app_card.dart`:

| Componente     | Descripción                                                                 |
|----------------|-----------------------------------------------------------------------------|
| `AppCard`      | Tarjeta base: fondo blanco, radius 16px, `cardShadow`, padding 16px, onTap opcional |
| `ImpactBadge`  | Badge naranja con texto (ej. "20% Impact"), radius 20px                     |
| `SectionHeader`| Fila título + acción opcional, estilo estandarizado                         |

Helpers de shadow en `app_theme.dart`:

| Helper          | Uso                                          |
|-----------------|----------------------------------------------|
| `cardShadow`    | Cards estándar — offset(0,4), opacity 0.05, radius 10 |
| `floatShadow`   | Elementos flotantes — offset(0,8), opacity 0.10, radius 20 |
| `primaryShadow` | Botones CTA — naranja opacity 0.30, offset(0,6), radius 16 |

---

## Pantallas cliente implementadas

| Pantalla                                                        | Archivo                                                   |
|-----------------------------------------------------------------|-----------------------------------------------------------|
| Login minimalista (Google + Apple)                              | `screens/customer/customer_login_screen.dart`             |
| Onboarding — 3 pasos: Phone → OTP → Perfil                     | `screens/customer/onboarding/onboarding_flow.dart`        |
| Home con bottom nav 3 tabs                                      | `screens/customer/customer_home.dart`                     |
| Browse causas + grid                                            | `screens/customer/customer_causes_screen.dart`            |
| Mi impacto — wallet con gradiente                               | `screens/customer/customer_impact_screen.dart`            |
| Cuenta                                                          | `screens/customer/customer_account_screen.dart`           |
| Sugerir causa                                                   | `screens/customer/refer_cause_screen.dart`                |

---

## Referencia visual rápida (diseños originales)

| Pantalla               | Archivo diseño              |
|------------------------|-----------------------------|
| Login (todas las apps) | Image 5.png + Image 6.html  |
| Login (welcome back)   | Image 13.png                |
| Completar perfil       | Image 7.png + Image 8.html  |
| Browse causas          | Image 17.png                |
| Mi impacto             | Image 15.png                |
| Sugerir causa (v1)     | Image 1.png + Image 2.html  |
| Sugerir causa (v2)     | Image 3.png + Image 4.html  |
| Cuenta                 | Image 19.png                |

---

## Cómo usar este agente

Cuando vayas a crear o revisar una pantalla:

1. Leer `docs/design-system.md`
2. Comparar con el diseño de referencia en `desing/` si existe
3. Recorrer el checklist de arriba
4. Si algo no cumple → corregirlo antes de continuar
5. Si el diseño de referencia no existe para esa pantalla → respetar los tokens y patrones establecidos en pantallas ya implementadas
6. Verificar que los componentes base (`AppCard`, `ImpactBadge`, `SectionHeader`) se usen donde corresponda en lugar de reimplementarlos
