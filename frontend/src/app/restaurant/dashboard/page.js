'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { api } from '@/lib/api'
import { getUser, clearTokens, formatCurrency } from '@/lib/auth'
import StatsCard from '@/components/dashboard/StatsCard'

export default function RestaurantDashboard() {
  const router = useRouter()
  const user = typeof window !== 'undefined' ? getUser() : null
  const [dashboard, setDashboard] = useState(null)
  const [profile, setProfile] = useState(null)
  const [recentOrders, setRecentOrders] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    if (!user || user.role !== 'RESTAURANT') {
      router.push('/login')
      return
    }
    loadData()
  }, [])

  async function loadData() {
    try {
      const [dashRes, profileRes, ordersRes] = await Promise.all([
        api.restaurant.getDashboard(),
        api.restaurant.getProfile(),
        api.orders.list({ limit: 5 }),
      ])
      setDashboard(dashRes.data)
      setProfile(profileRes.data)
      setRecentOrders(ordersRes.data.orders || [])
    } catch (err) {
      if (err.status === 401) {
        clearTokens()
        router.push('/login')
      } else {
        setError(err.message)
      }
    } finally {
      setLoading(false)
    }
  }

  function logout() {
    clearTokens()
    router.push('/')
  }

  if (loading) return (
    <div className="min-h-screen flex items-center justify-center bg-background">
      <div className="w-10 h-10 border-3 border-primary border-t-transparent rounded-full animate-spin" />
    </div>
  )

  return (
    <div className="min-h-screen bg-background pb-28">
      {/* Header */}
      <header className="bg-white border-b border-border sticky top-0 z-10 px-4 py-4 flex items-center justify-between" style={{ boxShadow: '0 1px 8px rgba(0,0,0,0.06)' }}>
        <div>
          <span className="text-xl font-extrabold text-primary">Unitia</span>
          <span className="text-muted ml-2 text-sm font-medium">· Restaurante</span>
        </div>
        <div className="flex items-center gap-3">
          <span className="text-sm text-muted font-medium hidden sm:block">{user?.name}</span>
          <button onClick={logout} className="text-sm text-muted hover:text-red-500 font-semibold transition-colors">Salir</button>
        </div>
      </header>

      <main className="max-w-2xl mx-auto px-4 py-6 space-y-4">
        {error && (
          <div className="p-4 bg-red-50 border border-red-200 rounded-2xl text-red-700 text-sm font-medium">{error}</div>
        )}

        {/* PEDIDOS — sección principal */}
        {(() => {
          const active = recentOrders.filter(o => o.status === 'PENDING' || o.status === 'CONFIRMED' || o.status === 'READY')
          const pendingCount = recentOrders.filter(o => o.status === 'PENDING').length
          return (
            <div>
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-2">
                  <h2 className="text-lg font-extrabold text-[#2D2D2D]">Pedidos activos</h2>
                  {pendingCount > 0 && (
                    <span className="bg-primary text-white text-xs font-extrabold px-2 py-0.5 rounded-full animate-pulse">
                      {pendingCount} nuevo{pendingCount > 1 ? 's' : ''}
                    </span>
                  )}
                </div>
                <Link href="/restaurant/orders" className="text-sm text-primary font-bold hover:underline flex items-center gap-1">
                  Ver todos
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} className="w-3.5 h-3.5">
                    <polyline points="9 18 15 12 9 6" />
                  </svg>
                </Link>
              </div>

              {active.length === 0 ? (
                <div className="card text-center py-8">
                  <p className="text-4xl mb-3">🍽</p>
                  <p className="text-muted text-sm font-medium">Sin pedidos activos ahora.</p>
                  <p className="text-xs text-muted mt-1">Los nuevos pedidos aparecerán aquí.</p>
                </div>
              ) : (
                <div className="space-y-3">
                  {active.map(order => {
                    const isPending = order.status === 'PENDING'
                    const isConfirmed = order.status === 'CONFIRMED'
                    const isReady = order.status === 'READY'
                    return (
                      <div key={order.id}
                        className="bg-white rounded-2xl border-l-4 overflow-hidden"
                        style={{
                          borderLeftColor: isPending ? '#F27F0D' : isConfirmed ? '#3B82F6' : '#22C55E',
                          boxShadow: isPending ? '0 2px 12px rgba(242,127,13,0.15)' : '0 2px 8px rgba(0,0,0,0.06)',
                        }}
                      >
                        <div className="p-4">
                          <div className="flex items-start justify-between gap-2 mb-2">
                            <div>
                              <p className="font-extrabold text-[#2D2D2D]">{order.customerName}</p>
                              <p className="text-xs text-muted mt-0.5">
                                {order.orderType === 'PICKUP' ? '🏪 Para recoger' : '🛵 A domicilio'}
                                {order.estimatedMinutes && isConfirmed ? ` · ⏱ ${order.estimatedMinutes} min` : ''}
                              </p>
                            </div>
                            <div className="text-right flex-shrink-0">
                              <p className="font-extrabold text-[#2D2D2D]">{formatCurrency(order.subtotal)}</p>
                              <span className={`text-xs font-extrabold px-2 py-0.5 rounded-full ${
                                isPending ? 'bg-orange-100 text-orange-700'
                                : isConfirmed ? 'bg-blue-100 text-blue-700'
                                : 'bg-green-100 text-green-700'
                              }`}>
                                {isPending ? '🔔 Nuevo' : isConfirmed ? 'En cocina' : '✅ Listo'}
                              </span>
                            </div>
                          </div>

                          <Link
                            href="/restaurant/orders"
                            className="w-full flex items-center justify-center gap-2 py-2 rounded-xl text-sm font-bold text-primary bg-primary-bg hover:bg-orange-100 transition-colors"
                          >
                            {isPending ? 'Aceptar pedido →' : isConfirmed ? 'Marcar como listo →' : 'Ver pedido →'}
                          </Link>
                        </div>
                      </div>
                    )
                  })}
                </div>
              )}

              <Link href="/restaurant/orders" className="mt-3 w-full flex items-center justify-center gap-2 py-3 rounded-2xl border-2 border-primary text-primary font-extrabold hover:bg-primary-bg transition-colors">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} className="w-5 h-5">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M9 5H7a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-2"/><rect x="9" y="3" width="6" height="4" rx="1"/>
                </svg>
                Gestionar todos los pedidos
              </Link>
            </div>
          )
        })()}

        {/* Stats */}
        {dashboard && (
          <div className="grid grid-cols-2 gap-3">
            <StatsCard label="Pedidos hoy" value={dashboard.todayOrders} color="primary"
              icon={<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4"><path strokeLinecap="round" strokeLinejoin="round" d="M9 5H7a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-2"/><rect x="9" y="3" width="6" height="4" rx="1"/></svg>} />
            <StatsCard label="Ventas hoy" value={formatCurrency(dashboard.todayRevenue)} color="green"
              icon={<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>} />
            <StatsCard label="Donaciones hoy" value={formatCurrency(dashboard.todayDonations)} color="orange"
              icon={<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4"><path strokeLinecap="round" strokeLinejoin="round" d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>} />
            <StatsCard
              label="Donaciones pendientes"
              value={formatCurrency(dashboard.donations.pending.total)}
              sub={`${dashboard.donations.pending.count} pedidos`}
              color="yellow"
              icon={<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>}
            />
          </div>
        )}

        {/* Share link */}
        {profile?.slug && (
          <div className="card flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-primary-bg flex items-center justify-center flex-shrink-0">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-5 h-5 text-primary">
                <path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8" />
                <polyline points="16 6 12 2 8 6" />
                <line x1="12" y1="2" x2="12" y2="15" />
              </svg>
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-xs text-muted font-semibold mb-0.5">TU LINK DE PEDIDOS</p>
              <p className="text-sm font-bold text-primary truncate">/r/{profile.slug}</p>
            </div>
            <Link href={`/r/${profile.slug}`} target="_blank" className="text-xs text-primary font-bold border border-border rounded-xl px-3 py-2 hover:bg-primary-bg transition-colors">
              Ver
            </Link>
          </div>
        )}
      </main>

    </div>
  )
}
