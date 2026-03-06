# Unitia — System Prompt

## What is Unitia?

Unitia is a platform that connects restaurants with social causes. Every order placed at a participating restaurant generates an automatic donation to a cause the restaurant has chosen to support. The mission is to make solidarity effortless — businesses keep doing what they do, and good things happen as a natural side effect.

## The Core Loop

1. A restaurant joins Unitia and selects a social cause they want to support.
2. The restaurant sets a donation percentage (e.g., 5% of every order).
3. Customers order normally — they see a note saying "X% of your order goes to [Cause]".
4. At the end of each period, the restaurant owes a donation amount to the cause.
5. The restaurant marks it as paid. The cause confirms receipt.
6. The cause page shows real progress — money raised, restaurants supporting them, impact.

## Who Uses Unitia?

### Restaurants
- Sign up, create a profile, choose a cause.
- Set up their menu (or import it).
- See a dashboard: orders taken, total sales, donations generated, payments pending.
- Mark donations as paid to causes.
- Earn "Solidarity Badges" for consistent donations.

### Causes (NGOs / Social Organizations)
- Sign up, create a public profile with their story and images.
- See which restaurants support them and how much is coming.
- Track received vs. pending donations.
- View progress toward fundraising goal.
- Share their public cause page to attract more restaurants.

### Customers
- Order at a participating restaurant.
- See the cause their restaurant supports.
- Know their meal is doing something good.

### Admins (Internal)
- Oversee the platform.
- Verify restaurants and causes.
- Manage disputes or payment issues.

## Business Model (MVP)

- Free for causes.
- Restaurants pay a small monthly subscription OR a platform fee per donation processed.
- Premium features: analytics, multiple causes, priority ranking.

## Core Values

- **Simplicity**: The restaurant should never feel burdened. Solidarity is a side effect, not a task.
- **Transparency**: Every peso/dollar donated is visible and traceable.
- **Trust**: Causes can verify payments. Restaurants can see their impact.
- **Growth**: The more restaurants join, the more causes benefit. Network effects matter.

## MVP Scope

### Must Have
- Restaurant registration + profile
- Cause registration + public page
- Menu management
- Order creation (basic form or QR-linked page)
- Automatic donation calculation per order
- Restaurant dashboard (orders, donations owed)
- Cause dashboard (donations received, pending)
- Payment marking system (restaurant marks as paid, cause confirms)

### Nice to Have (post-MVP)
- Cause ranking by impact
- Restaurant solidarity badges
- Shareable cause links with impact metrics
- Customer-facing order tracking
- Stripe/payment gateway integration
- Email notifications

## Technical Principles

- **Monorepo**: `/backend` + `/frontend` in one repo
- **Backend**: Node.js + Express + Prisma + PostgreSQL
- **Frontend**: Next.js 14 (App Router) + Tailwind CSS
- **Auth**: JWT with refresh tokens
- **API**: RESTful, versioned at `/api/v1`
- **Deployable**: Docker Compose for local dev, ready for Railway/Render/Vercel
- **Documented**: `/docs` folder always kept up to date

## Key Metrics to Track

- Total restaurants active
- Total causes supported
- Total donations generated (all time)
- Total donations confirmed paid
- Average donation per order
- Top causes by total raised
