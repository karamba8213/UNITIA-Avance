'use client'
import { useEffect, useState, useRef } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { api } from '@/lib/api'

function formatCurrency(n) {
  return new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(n || 0)
}

const STEPS = [
  { key: 'PENDING', label: 'Recibido' },
  { key: 'CONFIRMED', label: 'Confirmado' },
  { key: 'READY', label: 'Listo' },
  { key: 'COMPLETED', label: 'Entregado' },
]

const STATUS_STEP = {
  PENDING: 0,
  CONFIRMED: 1,
  READY: 2,
  COMPLETED: 3,
  CANCELLED: -1,
}

function getStatusMessage(status, causeName) {
  switch (status) {
    case 'PENDING': return '⏳ Esperando que el restaurante confirme tu pedido...'
    case 'CONFIRMED': return '👨‍🍳 El restaurante está preparando tu pedido'
    case 'READY': return '🛵 ¡Tu pedido está listo!'
    case 'COMPLETED': return `✅ ¡Entregado! Gracias por apoyar a ${causeName || 'la causa'}`
    case 'CANCELLED': return '❌ El pedido fue cancelado'
    default: return ''
  }
}

export default function PedidoPage({ params }) {
  const { id } = params
  const router = useRouter()
  const [order, setOrder] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [customerName, setCustomerName] = useState('Cliente')
  const intervalRef = useRef(null)

  useEffect(() => {
    // Get customerName from sessionStorage
    try {
      const raw = sessionStorage.getItem('unitia_last_order')
      if (raw) {
        const stored = JSON.parse(raw)
        if (stored.customerName) setCustomerName(stored.customerName)
      }
    } catch { /* ignore */ }

    loadOrder()
    intervalRef.current = setInterval(loadOrder, 5000)
    return () => clearInterval(intervalRef.current)
  }, [id])

  async function loadOrder() {
    try {
      const res = await api.orders.get(id)
      setOrder(res.data)
      setLoading(false)
      return
    } catch {
      // fall through to sessionStorage
    }

    try {
      const raw = sessionStorage.getItem('unitia_last_order')
      if (raw) {
        const stored = JSON.parse(raw)
        if (stored.id === id || !id) {
          setOrder(stored)
          setLoading(false)
          return
        }
      }
    } catch { /* ignore */ }

    setError('No se pudo cargar el pedido.')
    setLoading(false)
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="w-10 h-10 border-4 border-primary border-t-transparent rounded-full animate-spin" />
      </div>
    )
  }

  if (error || !order) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background px-4">
        <div className="card max-w-sm w-full text-center py-10">
          <p className="text-4xl mb-3">🍽</p>
          <p className="text-[#2D2D2D] font-bold mb-2">{error || 'Pedido no encontrado'}</p>
          <Link href="/" className="text-primary font-bold text-sm hover:underline">Volver al inicio</Link>
        </div>
      </div>
    )
  }

  const currentStep = STATUS_STEP[order.status] ?? 0
  const isCancelled = order.status === 'CANCELLED'
  const causeName = order.cause?.name
  const items = order.items || []

  return (
    <div className="min-h-screen bg-background pb-10">
      {/* Header */}
      <nav className="bg-white border-b border-border sticky top-0 z-40" style={{ boxShadow: '0 1px 8px rgba(0,0,0,0.06)' }}>
        <div className="max-w-xl mx-auto px-4 flex items-center h-14 gap-3">
          <Link href="/inicio" className="text-muted hover:text-primary transition-colors">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-5 h-5">
              <path strokeLinecap="round" strokeLinejoin="round" d="M19 12H5m7-7-7 7 7 7" />
            </svg>
          </Link>
          <h1 className="text-lg font-extrabold text-[#2D2D2D]">Tu pedido</h1>
        </div>
      </nav>

      <main className="max-w-xl mx-auto px-4 py-6 space-y-4">
        {/* Status message */}
        <div className="card text-center py-6">
          <p className="text-lg font-extrabold text-[#2D2D2D] mb-1">
            {order.restaurant?.name || 'Restaurante'}
          </p>
          <p className={`text-sm font-bold ${isCancelled ? 'text-red-500' : 'text-primary'}`}>
            {getStatusMessage(order.status, causeName)}
          </p>
          {order.estimatedMinutes && order.status === 'CONFIRMED' && (
            <div className="inline-flex items-center gap-1.5 mt-2 mb-3 bg-primary-bg text-primary px-4 py-1.5 rounded-full">
              <span className="text-base">⏱</span>
              <span className="text-sm font-extrabold">Listo en ~{order.estimatedMinutes} min</span>
            </div>
          )}
          {(!order.estimatedMinutes || order.status !== 'CONFIRMED') && <div className="mb-5" />}

          {/* Timeline */}
          {!isCancelled ? (
            <div className="flex items-center justify-between px-2 max-w-xs mx-auto">
              {STEPS.map((step, i) => {
                const isActive = i === currentStep
                const isDone = i < currentStep
                return (
                  <div key={step.key} className="flex flex-col items-center flex-1">
                    <div
                      className={`w-8 h-8 rounded-full flex items-center justify-center text-xs font-extrabold border-2 transition-all ${
                        isDone
                          ? 'bg-primary border-primary text-white'
                          : isActive
                          ? 'bg-primary border-primary text-white ring-4 ring-orange-100'
                          : 'bg-white border-border text-muted'
                      }`}
                    >
                      {isDone ? '✓' : i + 1}
                    </div>
                    <p className={`text-[10px] font-bold mt-1 ${isActive || isDone ? 'text-primary' : 'text-muted'}`}>
                      {step.label}
                    </p>
                    {i < STEPS.length - 1 && (
                      <div className="absolute" />
                    )}
                  </div>
                )
              })}
            </div>
          ) : (
            <div className="inline-flex items-center px-4 py-2 rounded-full bg-red-100 text-red-600 text-sm font-extrabold">
              Pedido cancelado
            </div>
          )}
        </div>

        {/* Items */}
        {items.length > 0 && (
          <div className="card">
            <h2 className="font-extrabold text-[#2D2D2D] mb-3">Artículos</h2>
            <div className="divide-y divide-border">
              {items.map((item, i) => (
                <div key={item.id || i} className="py-2.5 flex items-center justify-between text-sm">
                  <span className="text-muted font-medium">
                    {item.name || item.menuItem?.name || 'Artículo'} × {item.quantity}
                  </span>
                  <span className="font-bold text-[#2D2D2D]">
                    {formatCurrency(item.price * item.quantity)}
                  </span>
                </div>
              ))}
            </div>
            <div className="pt-3 border-t border-border space-y-2">
              <div className="flex justify-between text-sm">
                <span className="text-muted font-medium">Subtotal</span>
                <span className="font-extrabold text-[#2D2D2D]">{formatCurrency(order.subtotal)}</span>
              </div>
              {causeName && (
                <div className="flex justify-between text-sm">
                  <span className="text-primary font-bold">❤️ Donación a {causeName}</span>
                  <span className="text-primary font-extrabold">{formatCurrency(order.donationAmount)}</span>
                </div>
              )}
            </div>
          </div>
        )}

        {/* Cause */}
        {order.cause && (
          <div className="card flex items-center gap-3">
            {order.cause.logo ? (
              <img src={order.cause.logo} alt={causeName} className="w-12 h-12 rounded-2xl object-cover flex-shrink-0" />
            ) : (
              <div className="w-12 h-12 rounded-2xl bg-primary-bg flex items-center justify-center flex-shrink-0 text-xl">❤️</div>
            )}
            <div className="flex-1 min-w-0">
              <p className="text-xs text-muted font-semibold uppercase tracking-wide">Apoyaste a</p>
              <p className="font-extrabold text-primary text-sm">{causeName}</p>
              <p className="text-xs text-muted mt-0.5">{formatCurrency(order.donationAmount)} donados</p>
            </div>
          </div>
        )}

        {/* Chat button */}
        <button
          onClick={() => router.push(`/chat/${id}?role=CUSTOMER&name=${encodeURIComponent(customerName)}`)}
          className="btn w-full bg-white border-2 border-border text-[#2D2D2D] font-extrabold hover:border-primary hover:text-primary transition-colors flex items-center justify-center gap-2"
        >
          💬 Chatear con el restaurante
        </button>

        <Link href="/inicio" className="btn w-full text-center bg-white border-2 border-border text-[#2D2D2D] font-bold hover:border-primary hover:text-primary transition-colors">
          Volver al inicio
        </Link>
      </main>
    </div>
  )
}
