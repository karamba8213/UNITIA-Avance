# Unitia — Design System

## Tokens base (extraídos de los diseños)

### Colores
| Token          | Valor      | Uso                                      |
|----------------|------------|------------------------------------------|
| `primary`      | `#2D6A4F`  | Unitia green — marca, íconos activos     |
| `accent`       | `#F27F0D`  | CTA principal, botones de acción, labels |
| `background`   | `#F8F6F5`  | Fondo de pantallas (warm off-white)      |
| `surface`      | `#FFFFFF`  | Cards, inputs, bottom sheet              |
| `textPrimary`  | `#181411`  | Títulos y body principal                 |
| `textSecondary`| `#8A7560`  | Subtítulos, hints                        |
| `textMuted`    | `#9CA3AF`  | Metadata, timestamps                     |
| `error`        | `#EF4444`  |                                          |
| `success`      | `#10B981`  |                                          |
| `warning`      | `#F59E0B`  |                                          |

> El naranja `#F27F0D` actúa como color de acción (Rappi-style).
> El verde `#2D6A4F` es la identidad de marca Unitia.

### Tipografía
- **Font:** `Plus Jakarta Sans` (títulos y UI) / `Manrope` (formularios)
- Fallback actual: `Inter` (aceptable mientras no se agreguen los assets)
- Pesos: 400 (body), 600 (label), 700 (título), 800 (display/hero)

### Espaciado
- Padding de pantalla: `16-24px`
- Gap entre secciones: `20-28px`
- Gap entre items: `10-12px`

### Bordes y radios
| Elemento    | Radio  |
|-------------|--------|
| Card        | `20px` |
| Botón CTA   | `pill` (height/2) |
| Input       | `14px` (blanco con borde sutil) |
| Badge/chip  | `20px` |
| Avatar icon | `13px` |

### Sombras
```
Card:  0 4px 20px rgba(0,0,0,0.07)
Float: 0 8px 32px rgba(0,0,0,0.12)
CTA button: 0 6px 16px rgba(242,127,13,0.30)
```

### Inputs
- Fondo: **blanco** con borde `#E6E0DB` (no gris fill)
- Al focus: borde `primary` width 2, sin ring
- Label: uppercase, pequeño, color `accent/80`
- Height: `56px`

### Botones
- CTA principal: naranja `#F27F0D`, pill, shadow naranja
- Secundario: outline naranja
- Ghost: sin fondo, texto naranja
- Height: `52-56px`

### Bottom nav (cliente)
3 tabs: **CAUSES · IMPACT · ACCOUNT**
- Ícono activo: color `accent` (naranja)
- Texto: uppercase, bold, 10px

### Bottom nav (restaurante)
5 tabs: **Inicio · Pedidos · Donaciones · Menú · Perfil**

### Bottom nav (causa)
3 tabs: **Inicio · Donaciones · Perfil**

---

## Mapa de diseños → pantallas

### ✅ Aplicables — App Cliente

| Archivo diseño       | Pantalla Flutter                                    | Estado    |
|----------------------|-----------------------------------------------------|-----------|
| Image 5/6 + 13       | `screens/auth/login_screen.dart`                    | Adaptar   |
| Image 7/8            | `screens/customer/onboarding_details_screen.dart`   | Crear     |
| Image 17             | `screens/customer/customer_causes_screen.dart`      | Crear     |
| Image 15             | `screens/customer/customer_impact_screen.dart`      | Crear     |
| Image 1/2 + 3/4      | `screens/customer/refer_cause_screen.dart`          | Crear     |
| Image 19             | `screens/customer/customer_account_screen.dart`     | Crear     |

### ✅ Aplicables — Todas las apps
| Archivo diseño       | Pantalla Flutter                  |
|----------------------|-----------------------------------|
| Image 5/6 + 13       | Login hero con foto + Google/Apple |

### ❌ Descartados

| Archivo              | Motivo                                                              |
|----------------------|---------------------------------------------------------------------|
| Image 9 (Verify Phone)  | El auth usa Firebase (Google/Apple/email), no SMS. No aplica al MVP. |
| Image 11 (OTP screen)   | Mismo motivo — depende de SMS auth que no existe en el proyecto.    |

---

## Pantallas por app

### App Restaurante
```
login → restaurant_home (tabs: inicio, pedidos, donaciones, menú, perfil)
```

### App Causa
```
login → cause_home (tabs: inicio, donaciones, perfil)
```

### App Cliente
```
login → onboarding → customer_home
  tabs:
    CAUSES  → browse causas → seleccionar → hacer pedido
    IMPACT  → mi impacto total + historial + refer a cause
    ACCOUNT → perfil, nombre, email, teléfono, logout
```

---

## Reglas de diseño (enforcement)

Ver `agents/design-guardian.md`
