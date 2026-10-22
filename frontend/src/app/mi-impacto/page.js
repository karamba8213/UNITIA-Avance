'use client'
import { useState, useEffect } from 'react'
import Link from 'next/link'
import { getUser } from '@/lib/auth'
import { api } from '@/lib/api'

function formatCurrency(n) {
  return new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(n)
}

function formatDate(d) {
  return new Intl.DateTimeFormat('es-MX', { day: '2-digit', month: 'short', year: 'numeric' }).format(new Date(d))
}

// Compute impact summary from order list
function computeImpact(orders) {
  const totalOrders = orders.length
  const totalDonated = orders.reduce((s, o) => s + (o.donationAmount || 0), 0)
  const totalSpent = orders.reduce((s, o) => s + (o.subtotal || 0), 0)

  const causeMap = {}
  for (const order of orders) {
    if (!order.cause) continue
    const id = order.cause.id
    if (!causeMap[id]) causeMap[id] = { cause: order.cause, totalDonated: 0, orderCount: 0 }
    causeMap[id].totalDonated += order.donationAmount || 0
    causeMap[id].orderCount++
  }

  const byCause = Object.values(causeMap).sort((a, b) => b.totalDonated - a.totalDonated)
  const causesSupported = byCause.length

  const recentOrders = orders.slice(0, 10).map(o => ({
    id: o.id,
    date: o.createdAt,
    subtotal: o.subtotal,
    donationAmount: o.donationAmount,
    restaurant: o.restaurant,
    cause: o.cause,
  }))

  return { totalOrders, totalDonated, totalSpent, causesSupported, byCause, recentOrders }
}

function ImpactDisplay({ data }) {
  if (data.totalOrders === 0) {
    return (
      <div className="card text-center py-10">
        <p className="text-4xl mb-3">🌱</p>
        <p className="text-[#2D2D2D] font-bold">Aún no tienes pedidos.</p>
        <p className="text-muted text-sm mt-1 leading-relaxed">
          Cuando hagas un pedido en un restaurante Unitia, aparecerá aquí.
        </p>
        <Link href="/restaurantes" className="btn btn-primary mt-4 inline-block">Explorar restaurantes</Link>
      </div>
    )
  }

  return (
    <>
      <div className="grid grid-cols-2 gap-3 mb-5">
        <div className="card text-center">
          <div className="w-10 h-10 rounded-full bg-primary-bg flex items-center justify-center mx-auto mb-2">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-5 h-5 text-primary">
              <line x1="12" y1="1" x2="12" y2="23" />
              <path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6" />
            </svg>
          </div>
          <p className="text-xl font-extrabold text-[#2D2D2D] mb-0.5">
            {formatCurrency(data.totalSpent || 0)}
          </p>
          <p className="text-xs text-muted font-semibold uppercase tracking-wide">total gastado</p>
        </div>
        <div className="card text-center">
          <div className="w-10 h-10 rounded-full bg-primary-bg flex items-center justify-center mx-auto mb-2">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-5 h-5 text-primary">
              <path strokeLinecap="round" strokeLinejoin="round" d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
            </svg>
          </div>
          <p className="text-xl font-extrabold text-primary mb-0.5">
            {formatCurrency(data.totalDonated)}
          </p>
          <p className="text-xs text-muted font-semibold uppercase tracking-wide">total donado</p>
        </div>
        <div className="card text-center">
          <div className="w-10 h-10 rounded-full bg-primary-bg flex items-center justify-center mx-auto mb-2">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-5 h-5 text-primary">
              <circle cx="12" cy="12" r="10" />
              <path strokeLinecap="round" strokeLinejoin="round" d="M8 14s1.5 2 4 2 4-2 4-2" />
              <line x1="9" y1="9" x2="9.01" y2="9" />
              <line x1="15" y1="9" x2="15.01" y2="9" />
            </svg>
          </div>
          <p className="text-xl font-extrabold text-[#2D2D2D] mb-0.5">{data.causesSupported || 0}</p>
          <p className="text-xs text-muted font-semibold uppercase tracking-wide">causas apoyadas</p>
        </div>
        <div className="card text-center">
          <div className="w-10 h-10 rounded-full bg-primary-bg flex items-center justify-center mx-auto mb-2">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-5 h-5 text-primary">
              <path strokeLinecap="round" strokeLinejoin="round" d="M9 5H7a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-2" />
              <rect x="9" y="3" width="6" height="4" rx="1" ry="1" />
            </svg>
          </div>
          <p className="text-xl font-extrabold text-[#2D2D2D] mb-0.5">{data.totalOrders}</p>
          <p className="text-xs text-muted font-semibold uppercase tracking-wide">pedidos realizados</p>
        </div>
      </div>

      {data.byCause.length > 0 && (
        <div className="card mb-4">
          <h2 className="font-extrabold text-[#2D2D2D] mb-4">Tu donación por causa</h2>
          <div className="space-y-4">
            {data.byCause.map(({ cause, totalDonated, orderCount }) => (
              <div key={cause.id} className="flex items-center gap-3">
                {cause.logo ? (
                  <img src={cause.logo} alt={cause.name} className="w-11 h-11 rounded-2xl object-cover flex-shrink-0" />
                ) : (
                  <div className="w-11 h-11 rounded-2xl bg-primary-bg flex items-center justify-center text-primary font-extrabold flex-shrink-0">
                    {cause.name[0]}
                  </div>
                )}
                <div className="flex-1 min-w-0">
                  <Link href={`/c/${cause.slug}`} className="font-bold text-[#2D2D2D] hover:text-primary text-sm">
                    {cause.name}
                  </Link>
                  <p className="text-xs text-muted">{orderCount} pedido{orderCount !== 1 ? 's' : ''}</p>
                </div>
                <div className="text-right flex-shrink-0">
                  <p className="font-extrabold text-primary">{formatCurrency(totalDonated)}</p>
                  <p className="text-xs text-muted">donado</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      <div className="card">
        <h2 className="font-extrabold text-[#2D2D2D] mb-4">Historial reciente</h2>
        <div className="divide-y divide-border">
          {data.recentOrders.map(order => (
            <div key={order.id} className="py-3 flex items-start justify-between gap-4">
              <div className="min-w-0">
                <p className="text-sm font-bold text-[#2D2D2D]">{order.restaurant?.name}</p>
                <p className="text-xs text-muted">{formatDate(order.date)}</p>
                <p className="text-xs text-primary font-bold mt-0.5">→ {order.cause?.name}</p>
              </div>
              <div className="text-right flex-shrink-0">
                <p className="text-sm text-muted font-medium">{formatCurrency(order.subtotal)}</p>
                <p className="text-xs text-green-600 font-extrabold">+{formatCurrency(order.donationAmount)}</p>
              </div>
            </div>
          ))}
        </div>
      </div>

      <p className="text-center text-xs text-muted mt-6 font-medium">
        Gracias por elegir restaurantes que hacen el bien. ❤️
      </p>
    </>
  )
}

export default function MiImpactoPage() {
  const [loggedUser, setLoggedUser] = useState(null)
  const [customerData, setCustomerData] = useState(null)
  const [customerLoading, setCustomerLoading] = useState(false)


  useEffect(() => {
    const u = getUser()
    if (u?.role === 'CUSTOMER') {
      setLoggedUser(u)
      setCustomerLoading(true)
      api.customer.getOrders()
        .then(res => setCustomerData(computeImpact(res.data || [])))
        .catch(() => setCustomerData({ totalOrders: 0, totalDonated: 0, totalSpent: 0, causesSupported: 0, byCause: [], recentOrders: [] }))
        .finally(() => setCustomerLoading(false))
    }
  }, [])

  // Logged-in customer view
  if (loggedUser) {
    return (
      <div className="min-h-screen bg-background pb-24">
        <nav className="bg-white border-b border-border sticky top-0 z-40" style={{ boxShadow: '0 1px 8px rgba(0,0,0,0.06)' }}>
          <div className="max-w-xl mx-auto px-4 flex items-center h-14">
            <h1 className="text-lg font-extrabold text-[#2D2D2D]">Mi Impacto</h1>
          </div>
        </nav>

        <main className="max-w-xl mx-auto px-4 py-6">
          {customerLoading ? (
            <div className="flex items-center justify-center py-16">
              <div className="w-10 h-10 border-4 border-primary border-t-transparent rounded-full animate-spin" />
            </div>
          ) : customerData ? (
            <ImpactDisplay data={customerData} />
          ) : null}
        </main>

      </div>
    )
  }

  // Anonymous — redirect to login
  return (
    <div className="min-h-screen bg-background flex flex-col">
      <nav className="bg-white border-b border-border" style={{ boxShadow: '0 1px 8px rgba(0,0,0,0.06)' }}>
        <div className="max-w-xl mx-auto px-4 flex items-center h-14">
          <h1 className="text-lg font-extrabold text-[#2D2D2D]">Mi Impacto</h1>
        </div>
      </nav>

      <main className="flex-1 flex items-center justify-center px-4">
        <div className="card max-w-sm w-full text-center py-10">
          <div className="w-16 h-16 rounded-full bg-primary-bg flex items-center justify-center mx-auto mb-4 text-3xl">❤️</div>
          <h2 className="text-xl font-extrabold text-[#2D2D2D] mb-2">Tu impacto</h2>
          <p className="text-muted text-sm mb-6 leading-relaxed">
            Inicia sesión para ver cuánto has donado y las causas que has apoyado.
          </p>
          <Link href="/login?callbackUrl=/mi-impacto" className="btn btn-primary w-full">
            Iniciar sesión
          </Link>
          <p className="text-xs text-muted mt-4">
            ¿No tienes cuenta?{' '}
            <Link href="/registro" className="text-primary font-bold hover:underline">Regístrate gratis</Link>
          </p>
        </div>
      </main>
    </div>
  )
}
