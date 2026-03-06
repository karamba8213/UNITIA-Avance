'use client'
import { useState } from 'react'
import Link from 'next/link'

function formatCurrency(n) {
  return new Intl.NumberFormat('es-AR', { style: 'currency', currency: 'ARS' }).format(n)
}

function formatDate(d) {
  return new Intl.DateTimeFormat('es-AR', { day: '2-digit', month: 'short', year: 'numeric' }).format(new Date(d))
}

export default function MiImpactoPage() {
  const [email, setEmail] = useState('')
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [searched, setSearched] = useState(false)

  async function handleSearch(e) {
    e.preventDefault()
    if (!email) return
    setLoading(true)
    setError('')
    setData(null)
    try {
      const res = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/public/impact?email=${encodeURIComponent(email)}`
      )
      const json = await res.json()
      if (!json.success) throw new Error(json.error)
      setData(json.data)
      setSearched(true)
    } catch (err) {
      setError(err.message || 'Error al buscar')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white border-b border-gray-100">
        <div className="max-w-3xl mx-auto px-4 sm:px-6 flex items-center justify-between h-14">
          <Link href="/" className="text-lg font-bold text-primary">Unitia</Link>
        </div>
      </nav>

      <main className="max-w-3xl mx-auto px-4 sm:px-6 py-12">
        <div className="text-center mb-10">
          <h1 className="text-3xl font-bold text-gray-900 mb-3">Tu impacto</h1>
          <p className="text-gray-500">
            Ingresá el email que usaste al hacer tus pedidos y te mostramos cuánto has contribuido a causas sociales.
          </p>
        </div>

        <div className="card mb-8">
          <form onSubmit={handleSearch} className="flex gap-3">
            <input
              type="email"
              className="input flex-1"
              placeholder="tu@email.com"
              value={email}
              onChange={e => setEmail(e.target.value)}
              required
            />
            <button type="submit" className="btn-primary px-6" disabled={loading}>
              {loading ? '...' : 'Ver impacto'}
            </button>
          </form>
          {error && <p className="text-red-600 text-sm mt-3">{error}</p>}
        </div>

        {searched && data && data.totalOrders === 0 && (
          <div className="card text-center py-10">
            <p className="text-4xl mb-3">🌱</p>
            <p className="text-gray-600 font-medium">No encontramos pedidos con ese email.</p>
            <p className="text-gray-400 text-sm mt-1">
              Cuando hagas un pedido en un restaurante Unitia, aparecerá aquí.
            </p>
          </div>
        )}

        {searched && data && data.totalOrders > 0 && (
          <>
            {/* Summary */}
            <div className="grid grid-cols-2 gap-4 mb-6">
              <div className="card text-center">
                <p className="text-3xl font-bold text-primary mb-1">
                  {formatCurrency(data.totalDonated)}
                </p>
                <p className="text-sm text-gray-500">donado en total</p>
              </div>
              <div className="card text-center">
                <p className="text-3xl font-bold text-gray-700 mb-1">{data.totalOrders}</p>
                <p className="text-sm text-gray-500">pedidos realizados</p>
              </div>
            </div>

            {/* By cause */}
            <div className="card mb-6">
              <h2 className="font-semibold text-gray-900 mb-4">Tu donación por causa</h2>
              <div className="space-y-4">
                {data.byCause.map(({ cause, totalDonated, orderCount }) => (
                  <div key={cause.id} className="flex items-center gap-4">
                    {cause.logo ? (
                      <img src={cause.logo} alt={cause.name} className="w-10 h-10 rounded-full object-cover flex-shrink-0" />
                    ) : (
                      <div className="w-10 h-10 rounded-full bg-primary-100 flex items-center justify-center text-primary font-bold flex-shrink-0">
                        {cause.name[0]}
                      </div>
                    )}
                    <div className="flex-1 min-w-0">
                      <Link href={`/c/${cause.slug}`} className="font-medium text-gray-900 hover:text-primary text-sm">
                        {cause.name}
                      </Link>
                      <p className="text-xs text-gray-400">{orderCount} pedido{orderCount !== 1 ? 's' : ''}</p>
                    </div>
                    <div className="text-right flex-shrink-0">
                      <p className="font-bold text-primary">{formatCurrency(totalDonated)}</p>
                      <p className="text-xs text-gray-400">donado</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Recent orders */}
            <div className="card">
              <h2 className="font-semibold text-gray-900 mb-4">Historial reciente</h2>
              <div className="divide-y divide-gray-50">
                {data.recentOrders.map(order => (
                  <div key={order.id} className="py-3 flex items-start justify-between gap-4">
                    <div className="min-w-0">
                      <p className="text-sm font-medium text-gray-900">{order.restaurant?.name}</p>
                      <p className="text-xs text-gray-400">{formatDate(order.date)}</p>
                      <p className="text-xs text-primary mt-0.5">→ {order.cause?.name}</p>
                    </div>
                    <div className="text-right flex-shrink-0">
                      <p className="text-sm text-gray-700">{formatCurrency(order.subtotal)}</p>
                      <p className="text-xs text-green-600 font-medium">+{formatCurrency(order.donationAmount)}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <p className="text-center text-xs text-gray-400 mt-6">
              Gracias por elegir restaurantes que hacen el bien.
            </p>
          </>
        )}
      </main>
    </div>
  )
}
