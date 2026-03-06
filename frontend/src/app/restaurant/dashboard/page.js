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
    <div className="min-h-screen flex items-center justify-center">
      <div className="text-gray-400">Cargando...</div>
    </div>
  )

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white border-b border-gray-100 px-4 sm:px-6 py-4 flex items-center justify-between">
        <div>
          <span className="text-xl font-bold text-primary">Unitia</span>
          <span className="text-gray-400 ml-2 text-sm">· Restaurante</span>
        </div>
        <div className="flex items-center gap-4">
          <span className="text-sm text-gray-600 hidden sm:block">{user?.name}</span>
          <button onClick={logout} className="text-sm text-gray-500 hover:text-red-600">Salir</button>
        </div>
      </header>

      <main className="max-w-5xl mx-auto px-4 sm:px-6 py-8">
        <div className="mb-8 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">{profile?.name || 'Mi Restaurante'}</h1>
            {profile?.cause && (
              <p className="text-sm text-gray-500 mt-1">
                Apoyando a <span className="text-primary font-medium">{profile.cause.name}</span>
                {' · '}{profile.donationPercentage}% por pedido
              </p>
            )}
            {!profile?.cause && (
              <Link href="/restaurant/settings" className="text-sm text-accent font-medium mt-1 inline-block">
                + Elegir una causa para apoyar
              </Link>
            )}
          </div>
          <div className="flex gap-2 flex-wrap">
            <Link href="/restaurant/menu" className="btn-secondary text-sm">Gestionar menú</Link>
            <Link href="/restaurant/donations" className="btn-primary text-sm">Ver donaciones</Link>
          </div>
        </div>

        {error && (
          <div className="mb-6 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">{error}</div>
        )}

        {/* Stats */}
        {dashboard && (
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-8">
            <StatsCard label="Pedidos hoy" value={dashboard.todayOrders} color="primary" />
            <StatsCard label="Ventas hoy" value={formatCurrency(dashboard.todayRevenue)} color="green" />
            <StatsCard label="Donaciones hoy" value={formatCurrency(dashboard.todayDonations)} color="orange" />
            <StatsCard
              label="Donaciones pendientes"
              value={formatCurrency(dashboard.donations.pending.total)}
              sub={`${dashboard.donations.pending.count} pedidos`}
              color="yellow"
            />
          </div>
        )}

        {/* Recent orders */}
        <div className="card">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-semibold text-gray-900">Pedidos recientes</h2>
            <Link href="/restaurant/orders" className="text-sm text-primary hover:underline">Ver todos</Link>
          </div>
          {recentOrders.length === 0 ? (
            <p className="text-gray-400 text-sm text-center py-6">
              Aún no hay pedidos.{' '}
              {profile?.slug && (
                <>
                  Compartí el link:{' '}
                  <Link href={`/r/${profile.slug}`} className="text-primary underline">
                    /r/{profile.slug}
                  </Link>
                </>
              )}
            </p>
          ) : (
            <div className="divide-y divide-gray-50">
              {recentOrders.map(order => (
                <div key={order.id} className="py-3 flex items-center justify-between">
                  <div>
                    <p className="font-medium text-sm text-gray-900">{order.customerName}</p>
                    <p className="text-xs text-gray-400">{new Date(order.createdAt).toLocaleString('es-AR')}</p>
                  </div>
                  <div className="text-right">
                    <p className="font-semibold text-sm">{formatCurrency(order.subtotal)}</p>
                    <p className="text-xs text-primary">+{formatCurrency(order.donationAmount)} donación</p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </main>
    </div>
  )
}
