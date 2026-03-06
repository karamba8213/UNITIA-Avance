'use client'
import { useEffect, useState } from 'react'
import Link from 'next/link'
import { api } from '@/lib/api'

function groupByCategory(items) {
  const map = {}
  for (const item of items) {
    const cat = item.category || 'Sin categoría'
    if (!map[cat]) map[cat] = []
    map[cat].push(item)
  }
  return map
}

function formatCurrency(n) {
  return new Intl.NumberFormat('es-AR', { style: 'currency', currency: 'ARS' }).format(n)
}

export default function RestaurantOrderPage({ params }) {
  const { slug } = params
  const [restaurant, setRestaurant] = useState(null)
  const [loading, setLoading] = useState(true)
  const [cart, setCart] = useState({}) // { menuItemId: quantity }
  const [step, setStep] = useState('menu') // 'menu' | 'checkout' | 'success'
  const [form, setForm] = useState({ customerName: '', customerEmail: '', customerPhone: '', notes: '' })
  const [submitting, setSubmitting] = useState(false)
  const [order, setOrder] = useState(null)
  const [error, setError] = useState('')

  useEffect(() => {
    api.public.getRestaurant(slug)
      .then(r => setRestaurant(r.data))
      .catch(() => setRestaurant(null))
      .finally(() => setLoading(false))
  }, [slug])

  function addItem(id) {
    setCart(c => ({ ...c, [id]: (c[id] || 0) + 1 }))
  }
  function removeItem(id) {
    setCart(c => {
      const next = { ...c }
      if (next[id] <= 1) delete next[id]
      else next[id]--
      return next
    })
  }

  const cartItems = restaurant?.menuItems?.filter(i => cart[i.id]) || []
  const subtotal = cartItems.reduce((s, i) => s + i.price * cart[i.id], 0)
  const donationAmount = parseFloat((subtotal * (restaurant?.donationPercentage / 100 || 0)).toFixed(2))
  const cartCount = Object.values(cart).reduce((s, n) => s + n, 0)

  async function handleSubmit(e) {
    e.preventDefault()
    setSubmitting(true)
    setError('')
    try {
      const result = await api.orders.create({
        restaurantId: restaurant.id,
        ...form,
        items: Object.entries(cart).map(([menuItemId, quantity]) => ({ menuItemId, quantity })),
      })
      setOrder(result.data)
      setStep('success')
    } catch (err) {
      setError(err.message || 'Error al enviar el pedido')
    } finally {
      setSubmitting(false)
    }
  }

  if (loading) return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full animate-spin" />
    </div>
  )

  if (!restaurant) return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
      <div className="text-center">
        <p className="text-2xl font-bold text-gray-900 mb-2">Restaurante no encontrado</p>
        <Link href="/" className="text-primary hover:underline text-sm">Volver al inicio</Link>
      </div>
    </div>
  )

  if (step === 'success' && order) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
        <div className="card max-w-sm w-full text-center">
          <div className="text-5xl mb-4">🎉</div>
          <h1 className="text-2xl font-bold text-gray-900 mb-2">¡Pedido confirmado!</h1>
          <p className="text-gray-500 text-sm mb-6">
            Gracias, <strong>{order.customerName}</strong>. Tu pedido fue recibido.
          </p>

          <div className="bg-primary-50 rounded-xl p-4 mb-6 text-left space-y-2">
            <div className="flex justify-between text-sm">
              <span className="text-gray-600">Subtotal</span>
              <span className="font-medium">{formatCurrency(order.subtotal)}</span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-primary font-medium">
                Donación a {order.cause?.name}
              </span>
              <span className="text-primary font-bold">{formatCurrency(order.donationAmount)}</span>
            </div>
          </div>

          <p className="text-xs text-gray-400 mb-4">
            El {restaurant.donationPercentage}% de tu pedido irá a{' '}
            <Link href={`/c/${order.cause?.slug}`} className="text-primary underline">
              {order.cause?.name}
            </Link>. Gracias por hacer el bien.
          </p>

          <Link href={`/mi-impacto`} className="text-sm text-primary hover:underline block">
            Ver mi historial de impacto →
          </Link>
        </div>
      </div>
    )
  }

  const grouped = groupByCategory(restaurant.menuItems || [])

  return (
    <div className="min-h-screen bg-gray-50 pb-32">
      {/* Header */}
      <div className="bg-white border-b border-gray-100 sticky top-0 z-40">
        <div className="max-w-2xl mx-auto px-4 py-4 flex items-center gap-3">
          {restaurant.logo && (
            <img src={restaurant.logo} alt={restaurant.name} className="w-10 h-10 rounded-full object-cover" />
          )}
          <div className="flex-1 min-w-0">
            <h1 className="font-bold text-gray-900 truncate">{restaurant.name}</h1>
            {restaurant.cause && (
              <p className="text-xs text-primary truncate">
                {restaurant.donationPercentage}% de cada pedido → {restaurant.cause.name}
              </p>
            )}
          </div>
        </div>
      </div>

      {step === 'menu' && (
        <div className="max-w-2xl mx-auto px-4 py-6">
          {restaurant.cause && (
            <Link href={`/c/${restaurant.cause.slug}`} className="flex items-center gap-3 card mb-6 hover:shadow-md transition-shadow">
              {restaurant.cause.logo && (
                <img src={restaurant.cause.logo} alt="" className="w-10 h-10 rounded-full object-cover" />
              )}
              <div className="flex-1">
                <p className="text-xs text-gray-500">Apoyando a</p>
                <p className="font-semibold text-primary text-sm">{restaurant.cause.name}</p>
                <p className="text-xs text-gray-400 line-clamp-1">{restaurant.cause.description}</p>
              </div>
              <span className="text-xs text-primary">Ver →</span>
            </Link>
          )}

          {Object.entries(grouped).map(([cat, items]) => (
            <div key={cat} className="mb-6">
              <h2 className="font-semibold text-gray-700 text-sm uppercase tracking-wide mb-3 px-1">{cat}</h2>
              <div className="space-y-2">
                {items.map(item => (
                  <div key={item.id} className="card flex items-center gap-3 p-4">
                    {item.imageUrl && (
                      <img src={item.imageUrl} alt={item.name} className="w-14 h-14 rounded-lg object-cover flex-shrink-0" />
                    )}
                    <div className="flex-1 min-w-0">
                      <p className="font-medium text-gray-900 text-sm">{item.name}</p>
                      {item.description && (
                        <p className="text-xs text-gray-400 line-clamp-2 mt-0.5">{item.description}</p>
                      )}
                      <p className="font-bold text-primary mt-1">{formatCurrency(item.price)}</p>
                    </div>
                    <div className="flex items-center gap-2 flex-shrink-0">
                      {cart[item.id] ? (
                        <>
                          <button onClick={() => removeItem(item.id)} className="w-7 h-7 rounded-full border border-gray-300 flex items-center justify-center text-gray-700 hover:bg-gray-100 font-bold text-lg leading-none">−</button>
                          <span className="w-5 text-center font-semibold text-sm">{cart[item.id]}</span>
                        </>
                      ) : null}
                      <button onClick={() => addItem(item.id)} className="w-7 h-7 rounded-full bg-primary text-white flex items-center justify-center hover:bg-primary-600 font-bold text-lg leading-none">+</button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}

      {step === 'checkout' && (
        <div className="max-w-2xl mx-auto px-4 py-6">
          <button onClick={() => setStep('menu')} className="text-sm text-gray-500 hover:text-gray-700 mb-4 flex items-center gap-1">
            ← Volver al menú
          </button>
          <h2 className="text-xl font-bold text-gray-900 mb-4">Tu pedido</h2>

          <div className="card mb-4">
            {cartItems.map(item => (
              <div key={item.id} className="flex justify-between py-2 text-sm border-b border-gray-50 last:border-0">
                <span className="text-gray-700">{item.name} × {cart[item.id]}</span>
                <span className="font-medium">{formatCurrency(item.price * cart[item.id])}</span>
              </div>
            ))}
            <div className="flex justify-between pt-3 text-sm">
              <span className="text-gray-500">Subtotal</span>
              <span className="font-semibold">{formatCurrency(subtotal)}</span>
            </div>
            {restaurant.cause && (
              <div className="flex justify-between pt-1 text-sm">
                <span className="text-primary">Donación a {restaurant.cause.name}</span>
                <span className="text-primary font-bold">{formatCurrency(donationAmount)}</span>
              </div>
            )}
          </div>

          {error && (
            <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">{error}</div>
          )}

          <form onSubmit={handleSubmit} className="card space-y-4">
            <h3 className="font-semibold text-gray-900">Tus datos</h3>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Nombre *</label>
              <input className="input" value={form.customerName} onChange={e => setForm(f => ({ ...f, customerName: e.target.value }))} required />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Email <span className="text-gray-400">(para ver tu impacto)</span></label>
              <input type="email" className="input" value={form.customerEmail} onChange={e => setForm(f => ({ ...f, customerEmail: e.target.value }))} />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Teléfono</label>
              <input type="tel" className="input" value={form.customerPhone} onChange={e => setForm(f => ({ ...f, customerPhone: e.target.value }))} />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Notas para el pedido</label>
              <textarea className="input resize-none" rows={2} value={form.notes} onChange={e => setForm(f => ({ ...f, notes: e.target.value }))} />
            </div>
            <button type="submit" className="btn-primary w-full text-base py-3" disabled={submitting}>
              {submitting ? 'Enviando...' : `Confirmar pedido · ${formatCurrency(subtotal)}`}
            </button>
          </form>
        </div>
      )}

      {/* Floating cart bar */}
      {step === 'menu' && cartCount > 0 && (
        <div className="fixed bottom-0 left-0 right-0 p-4 bg-white border-t border-gray-100 shadow-lg z-50">
          <div className="max-w-2xl mx-auto">
            <button onClick={() => setStep('checkout')} className="btn-primary w-full py-3 text-base flex items-center justify-between">
              <span className="bg-white/20 rounded-full w-6 h-6 flex items-center justify-center text-sm font-bold">{cartCount}</span>
              <span>Ver pedido</span>
              <span>{formatCurrency(subtotal)}</span>
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
