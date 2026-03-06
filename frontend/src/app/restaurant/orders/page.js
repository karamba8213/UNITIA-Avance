'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { api } from '@/lib/api'
import { getUser, clearTokens, formatCurrency, formatDate } from '@/lib/auth'

export default function RestaurantOrdersPage() {
  const router = useRouter()
  const user = typeof window !== 'undefined' ? getUser() : null
  const [data, setData] = useState({ orders: [], total: 0, pages: 1 })
  const [loading, setLoading] = useState(true)
  const [page, setPage] = useState(1)
  const [expanded, setExpanded] = useState(null)

  useEffect(() => {
    if (!user || user.role !== 'RESTAURANT') { router.push('/login'); return }
    loadOrders()
  }, [page])

  async function loadOrders() {
    setLoading(true)
    try {
      const res = await api.orders.list({ page, limit: 20 })
      setData(res.data)
    } catch (err) {
      if (err.status === 401) { clearTokens(); router.push('/login') }
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white border-b border-gray-100 px-4 sm:px-6 py-4 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Link href="/restaurant/dashboard" className="text-gray-400 hover:text-gray-600 text-sm">← Dashboard</Link>
          <span className="text-gray-200">|</span>
          <span className="font-semibold text-gray-900">Pedidos</span>
        </div>
        <span className="text-sm text-gray-500">{data.total} total</span>
      </header>

      <main className="max-w-4xl mx-auto px-4 sm:px-6 py-8">
        {loading ? (
          <div className="text-center text-gray-400 py-12">Cargando...</div>
        ) : data.orders.length === 0 ? (
          <div className="card text-center py-12">
            <p className="text-gray-500">Aún no hay pedidos.</p>
          </div>
        ) : (
          <>
            <div className="space-y-2">
              {data.orders.map(order => (
                <div key={order.id} className="card p-0 overflow-hidden">
                  <button
                    onClick={() => setExpanded(expanded === order.id ? null : order.id)}
                    className="w-full px-5 py-4 flex items-center gap-4 text-left hover:bg-gray-50 transition-colors"
                  >
                    <div className="flex-1 min-w-0">
                      <p className="font-medium text-gray-900 text-sm">{order.customerName}</p>
                      <p className="text-xs text-gray-400">{formatDate(order.createdAt)}</p>
                    </div>
                    <div className="text-right flex-shrink-0">
                      <p className="font-semibold text-gray-900">{formatCurrency(order.subtotal)}</p>
                      <p className="text-xs text-primary">+{formatCurrency(order.donationAmount)}</p>
                    </div>
                    <span className={`badge-${order.donation?.status?.toLowerCase() || 'pending'} flex-shrink-0`}>
                      {order.donation?.status || 'PENDING'}
                    </span>
                    <span className="text-gray-400 text-sm">{expanded === order.id ? '▲' : '▼'}</span>
                  </button>

                  {expanded === order.id && (
                    <div className="px-5 pb-4 border-t border-gray-50 bg-gray-50/50">
                      <div className="pt-3 space-y-1">
                        {order.items?.map(item => (
                          <div key={item.id} className="flex justify-between text-sm text-gray-600">
                            <span>{item.name} × {item.quantity}</span>
                            <span>{formatCurrency(item.price * item.quantity)}</span>
                          </div>
                        ))}
                      </div>
                      {order.cause && (
                        <p className="text-xs text-primary mt-3">
                          Donación de {formatCurrency(order.donationAmount)} a{' '}
                          <Link href={`/c/${order.cause.slug}`} className="underline">{order.cause.name}</Link>
                        </p>
                      )}
                      {order.notes && (
                        <p className="text-xs text-gray-500 mt-1">Nota: "{order.notes}"</p>
                      )}
                    </div>
                  )}
                </div>
              ))}
            </div>

            {/* Pagination */}
            {data.pages > 1 && (
              <div className="flex justify-center gap-2 mt-6">
                <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1} className="btn-secondary text-sm px-3 py-1.5">
                  ← Anterior
                </button>
                <span className="px-3 py-1.5 text-sm text-gray-500">
                  {page} / {data.pages}
                </span>
                <button onClick={() => setPage(p => Math.min(data.pages, p + 1))} disabled={page === data.pages} className="btn-secondary text-sm px-3 py-1.5">
                  Siguiente →
                </button>
              </div>
            )}
          </>
        )}
      </main>
    </div>
  )
}
