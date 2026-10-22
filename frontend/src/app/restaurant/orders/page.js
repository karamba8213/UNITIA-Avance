'use client'
import { useEffect, useState, useRef } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { api } from '@/lib/api'
import { getUser, clearTokens } from '@/lib/auth'

function formatCurrency(n) {
  return new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(n || 0)
}

function timeAgo(dateStr) {
  const diff = Math.floor((Date.now() - new Date(dateStr)) / 1000)
  if (diff < 60) return `hace ${diff}s`
  if (diff < 3600) return `hace ${Math.floor(diff / 60)} min`
  if (diff < 86400) return `hace ${Math.floor(diff / 3600)}h`
  return `hace ${Math.floor(diff / 86400)}d`
}

const STATUS_ORDER = { PENDING: 0, CONFIRMED: 1, READY: 2, COMPLETED: 3, CANCELLED: 4 }

function StatusBadge({ status }) {
  const configs = {
    PENDING: { label: 'Nuevo pedido 🔔', cls: 'bg-orange-100 text-orange-700 animate-pulse' },
    CONFIRMED: { label: 'Confirmado', cls: 'bg-blue-100 text-blue-700' },
    READY: { label: 'Listo para entregar', cls: 'bg-green-100 text-green-700' },
    COMPLETED: { label: 'Completado', cls: 'bg-gray-100 text-gray-500' },
    CANCELLED: { label: 'Cancelado', cls: 'bg-red-100 text-red-600' },
  }
  const { label, cls } = configs[status] || configs.PENDING
  return (
    <span className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-extrabold ${cls}`}>
      {label}
    </span>
  )
}

const TIME_OPTIONS = [10, 15, 20, 30, 45, 60]

function OrderCard({ order, onUpdateStatus, router }) {
  const [loading, setLoading] = useState(false)
  const [confirming, setConfirming] = useState(false) // show time picker
  const [estimatedMinutes, setEstimatedMinutes] = useState(20)

  async function handleStatus(status, extra = {}) {
    setLoading(true)
    try {
      await onUpdateStatus(order.id, status, extra)
    } finally {
      setLoading(false)
      setConfirming(false)
    }
  }

  return (
    <div className="card p-0 overflow-hidden border-l-4"
      style={{
        borderLeftColor:
          order.status === 'PENDING' ? '#FF7A1A'
          : order.status === 'CONFIRMED' ? '#3B82F6'
          : order.status === 'READY' ? '#22C55E'
          : '#D1D5DB'
      }}
    >
      <div className="px-5 pt-4 pb-3">
        {/* Header row */}
        <div className="flex items-start justify-between gap-3 mb-3">
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 flex-wrap">
              <p className="font-extrabold text-[#2D2D2D] text-sm">{order.customerName}</p>
              <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                order.orderType === 'PICKUP'
                  ? 'bg-blue-100 text-blue-700'
                  : 'bg-orange-100 text-orange-700'
              }`}>
                {order.orderType === 'PICKUP' ? '🏪 Recoger' : '🛵 Domicilio'}
              </span>
            </div>
            {order.customerPhone && (
              <p className="text-xs text-muted font-medium">{order.customerPhone}</p>
            )}
            {order.orderType === 'DELIVERY' && order.deliveryAddress && (
              <p className="text-xs text-muted mt-0.5">📍 {order.deliveryAddress}</p>
            )}
            <p className="text-xs text-muted mt-0.5">{timeAgo(order.createdAt)}</p>
          </div>
          <div className="flex flex-col items-end gap-1.5 flex-shrink-0">
            <StatusBadge status={order.status} />
            <p className="font-extrabold text-[#2D2D2D] text-sm">{formatCurrency(order.subtotal)}</p>
          </div>
        </div>

        {/* Items */}
        <div className="space-y-1 mb-3">
          {order.items?.map(item => (
            <div key={item.id} className="flex justify-between text-sm">
              <span className="text-muted font-medium">{item.name} × {item.quantity}</span>
              <span className="font-semibold text-[#2D2D2D]">{formatCurrency(item.price * item.quantity)}</span>
            </div>
          ))}
        </div>

        {/* Donation + cause */}
        {order.cause && (
          <p className="text-xs text-primary font-bold mb-2">
            ❤️ {formatCurrency(order.donationAmount)} para {order.cause.name}
          </p>
        )}

        {/* Notes */}
        {order.notes && (
          <p className="text-xs text-muted bg-background rounded-lg px-3 py-2 mb-3 italic">
            "{order.notes}"
          </p>
        )}

        {/* Action buttons */}
        <div className="flex flex-wrap gap-2 mt-1">
          {order.status === 'PENDING' && (
            <>
              {confirming ? (
                <div className="w-full space-y-3">
                  <p className="text-xs font-bold text-[#2D2D2D]">¿En cuánto tiempo estará listo?</p>
                  <div className="flex flex-wrap gap-2">
                    {TIME_OPTIONS.map(min => (
                      <button
                        key={min}
                        type="button"
                        onClick={() => setEstimatedMinutes(min)}
                        className={`px-3 py-1.5 rounded-xl text-xs font-bold border-2 transition-all ${
                          estimatedMinutes === min
                            ? 'bg-primary text-white border-primary'
                            : 'bg-white text-muted border-border hover:border-primary hover:text-primary'
                        }`}
                      >
                        {min} min
                      </button>
                    ))}
                  </div>
                  <div className="flex gap-2">
                    <button
                      onClick={() => handleStatus('CONFIRMED', { estimatedMinutes })}
                      disabled={loading}
                      className="flex-1 btn btn-primary text-sm py-2 font-extrabold"
                    >
                      {loading ? '...' : `✓ Confirmar · ${estimatedMinutes} min`}
                    </button>
                    <button
                      onClick={() => setConfirming(false)}
                      className="btn text-sm py-2 px-4 font-bold bg-white border border-border rounded-xl"
                    >
                      Volver
                    </button>
                  </div>
                </div>
              ) : (
                <>
                  <button
                    onClick={() => setConfirming(true)}
                    disabled={loading}
                    className="flex-1 btn btn-primary text-sm py-2 font-extrabold"
                  >
                    ✓ Aceptar pedido
                  </button>
                  <button
                    onClick={() => handleStatus('CANCELLED')}
                    disabled={loading}
                    className="btn text-sm py-2 font-bold bg-red-50 text-red-600 border border-red-200 hover:bg-red-100 transition-colors rounded-xl px-4"
                  >
                    ✗ Cancelar
                  </button>
                </>
              )}
            </>
          )}
          {order.status === 'CONFIRMED' && (
            <>
              {order.estimatedMinutes && (
                <div className="w-full flex items-center gap-2 mb-2 px-1">
                  <span className="text-lg">⏱</span>
                  <span className="text-sm font-bold text-[#2D2D2D]">Tiempo estimado: {order.estimatedMinutes} min</span>
                </div>
              )}
              <button
                onClick={() => handleStatus('READY')}
                disabled={loading}
                className="flex-1 btn text-sm py-2 font-extrabold bg-green-500 text-white hover:bg-green-600 transition-colors rounded-xl"
              >
                {loading ? '...' : 'Listo para entregar'}
              </button>
              <button
                onClick={() => handleStatus('CANCELLED')}
                disabled={loading}
                className="btn text-sm py-2 font-bold bg-gray-100 text-gray-500 border border-gray-200 hover:bg-gray-200 transition-colors rounded-xl px-4"
              >
                Cancelar
              </button>
            </>
          )}
          {order.status === 'READY' && (
            <button
              onClick={() => handleStatus('COMPLETED')}
              disabled={loading}
              className="flex-1 btn text-sm py-2 font-extrabold bg-blue-500 text-white hover:bg-blue-600 transition-colors rounded-xl"
            >
              {loading ? '...' : 'Entregado'}
            </button>
          )}

          {/* Chat button */}
          <button
            onClick={() => router.push(`/chat/${order.id}?role=RESTAURANT`)}
            className="btn text-sm py-2 font-bold bg-white border border-border text-[#2D2D2D] hover:border-primary hover:text-primary transition-colors rounded-xl px-4 flex items-center gap-1"
          >
            💬 Chat
          </button>
        </div>
      </div>
    </div>
  )
}

export default function RestaurantOrdersPage() {
  const router = useRouter()
  const [user, setUser] = useState(null)
  const [allOrders, setAllOrders] = useState([])
  const [loading, setLoading] = useState(true)
  const [activeTab, setActiveTab] = useState('active')
  const intervalRef = useRef(null)

  useEffect(() => {
    const u = getUser()
    if (!u || u.role !== 'RESTAURANT') { router.push('/login'); return }
    setUser(u)
    loadOrders()
    intervalRef.current = setInterval(loadOrders, 5000)
    return () => clearInterval(intervalRef.current)
  }, [])

  async function loadOrders() {
    try {
      const res = await api.orders.list({ limit: 100 })
      const orders = res.data?.orders || []
      // Sort: PENDING first, then CONFIRMED, then READY, then rest
      orders.sort((a, b) => (STATUS_ORDER[a.status] ?? 99) - (STATUS_ORDER[b.status] ?? 99))
      setAllOrders(orders)
    } catch (err) {
      if (err.status === 401) { clearTokens(); router.push('/login') }
    } finally {
      setLoading(false)
    }
  }

  async function handleUpdateStatus(orderId, status, extra = {}) {
    await api.orders.updateStatus(orderId, status, extra)
    await loadOrders()
  }

  const activeOrders = allOrders.filter(o => ['PENDING', 'CONFIRMED', 'READY'].includes(o.status))
  const historyOrders = allOrders.filter(o => ['COMPLETED', 'CANCELLED'].includes(o.status))
  const displayed = activeTab === 'active' ? activeOrders : historyOrders

  return (
    <div className="min-h-screen bg-background pb-28">
      <header className="bg-white border-b border-border sticky top-0 z-10 px-4 py-4" style={{ boxShadow: '0 1px 8px rgba(0,0,0,0.06)' }}>
        <div className="flex items-center gap-3 max-w-2xl mx-auto">
          <Link
            href="/restaurant/dashboard"
            className="w-9 h-9 rounded-xl border border-border flex items-center justify-center text-muted hover:text-primary transition-colors"
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4">
              <polyline points="15 18 9 12 15 6" />
            </svg>
          </Link>
          <h1 className="font-extrabold text-[#2D2D2D]">Pedidos</h1>
          <div className="flex items-center gap-1.5 ml-auto">
            <span className="relative flex h-2.5 w-2.5">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-green-500"></span>
            </span>
            <span className="text-xs font-bold text-green-600">En vivo</span>
          </div>
        </div>
      </header>

      {/* Tabs */}
      <div className="max-w-2xl mx-auto px-4 pt-4">
        <div className="flex gap-2 bg-white border border-border rounded-2xl p-1">
          <button
            onClick={() => setActiveTab('active')}
            className={`flex-1 py-2.5 text-sm font-extrabold rounded-xl transition-all ${
              activeTab === 'active'
                ? 'bg-primary text-white shadow-sm'
                : 'text-muted hover:text-primary'
            }`}
          >
            Activos
            {activeOrders.length > 0 && (
              <span className={`ml-1.5 inline-flex items-center justify-center w-5 h-5 text-xs rounded-full ${
                activeTab === 'active' ? 'bg-white text-primary' : 'bg-primary text-white'
              }`}>
                {activeOrders.length}
              </span>
            )}
          </button>
          <button
            onClick={() => setActiveTab('history')}
            className={`flex-1 py-2.5 text-sm font-extrabold rounded-xl transition-all ${
              activeTab === 'history'
                ? 'bg-primary text-white shadow-sm'
                : 'text-muted hover:text-primary'
            }`}
          >
            Historial
          </button>
        </div>
      </div>

      <main className="max-w-2xl mx-auto px-4 py-4">
        {loading ? (
          <div className="text-center text-muted py-12 font-medium">Cargando...</div>
        ) : displayed.length === 0 ? (
          <div className="card text-center py-12">
            <p className="text-4xl mb-3">{activeTab === 'active' ? '🍽' : '📋'}</p>
            <p className="text-muted font-medium">
              {activeTab === 'active' ? 'No hay pedidos activos.' : 'No hay pedidos en el historial.'}
            </p>
          </div>
        ) : (
          <div className="space-y-3">
            {displayed.map(order => (
              <OrderCard
                key={order.id}
                order={order}
                onUpdateStatus={handleUpdateStatus}
                router={router}
              />
            ))}
          </div>
        )}
      </main>

    </div>
  )
}
