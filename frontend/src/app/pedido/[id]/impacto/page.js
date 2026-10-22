'use client'
import { useEffect, useState } from 'react'
import Link from 'next/link'

function formatCurrency(n) {
  return new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(n)
}

export default function PedidoImpactoPage({ params }) {
  const { id } = params
  const [order, setOrder] = useState(null)

  useEffect(() => {
    try {
      const raw = sessionStorage.getItem('unitia_last_order')
      if (raw) {
        setOrder(JSON.parse(raw))
      }
    } catch {
      // ignore
    }
  }, [])

  async function handleShare() {
    const text = order?.cause
      ? `Acabo de apoyar a "${order.cause.name}" con mi pedido en Unitia. ¡Cada comida hace la diferencia!`
      : '¡Hice un pedido en Unitia y apoyé una causa!'
    try {
      await navigator.share({
        title: 'Apoyé una causa en Unitia',
        text,
        url: window.location.href,
      })
    } catch {
      // fallback: copy to clipboard
      try {
        await navigator.clipboard.writeText(text + ' ' + window.location.href)
        alert('¡Enlace copiado!')
      } catch {
        // ignore
      }
    }
  }

  if (!order) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background px-4">
        <div className="card max-w-sm w-full text-center py-10">
          <div
            className="w-20 h-20 rounded-full bg-primary-bg flex items-center justify-center mx-auto mb-4"
            style={{ animation: 'pulse 1.5s ease-in-out infinite' }}
          >
            <span className="text-4xl">❤️</span>
          </div>
          <h1 className="text-2xl font-extrabold text-[#2D2D2D] mb-1">¡Pedido realizado!</h1>
          <p className="text-muted text-sm mb-6 font-medium">Esperando confirmación del restaurante</p>
          <Link href={`/pedido/${id}`} className="btn btn-primary w-full mb-3">
            Ver estado del pedido
          </Link>
          <Link href="/inicio" className="btn w-full bg-white border-2 border-border text-[#2D2D2D] font-bold hover:border-primary hover:text-primary transition-colors">
            Volver al inicio
          </Link>
        </div>
      </div>
    )
  }

  const donationAmount = order.donationAmount || 0
  const causeName = order.cause?.name
  const causeDescription = order.cause?.description
  const causeLogo = order.cause?.logo

  return (
    <div className="min-h-screen bg-background flex flex-col items-center justify-center px-4 py-10">
      <style>{`
        @keyframes heartbeat {
          0%, 100% { transform: scale(1); }
          25% { transform: scale(1.15); }
          50% { transform: scale(1); }
          75% { transform: scale(1.08); }
        }
        .heartbeat {
          animation: heartbeat 1.4s ease-in-out infinite;
        }
        @keyframes fadeInUp {
          from { opacity: 0; transform: translateY(20px); }
          to { opacity: 1; transform: translateY(0); }
        }
        .fade-in-up {
          animation: fadeInUp 0.5s ease-out forwards;
        }
      `}</style>

      <div className="max-w-sm w-full text-center">
        {/* Heart animation */}
        <div className="mb-6">
          <div
            className="heartbeat w-24 h-24 rounded-full bg-primary flex items-center justify-center mx-auto"
            style={{ boxShadow: '0 0 0 0 rgba(242,127,13,0.4)', animation: 'heartbeat 1.4s ease-in-out infinite' }}
          >
            <span className="text-4xl">❤️</span>
          </div>
        </div>

        <div className="fade-in-up">
          <h1 className="text-3xl font-extrabold text-[#2D2D2D] mb-1">¡Pedido realizado!</h1>
          <p className="text-sm text-muted font-medium mb-1">Esperando confirmación del restaurante</p>

          {causeName && donationAmount > 0 && (
            <p className="text-lg font-bold text-primary mb-4">
              Acabas de donar {formatCurrency(donationAmount)} a {causeName}
            </p>
          )}

          {/* Cause card */}
          {causeName && (
            <div className="card mb-6 text-left">
              <div className="flex items-center gap-3 mb-3">
                {causeLogo ? (
                  <img src={causeLogo} alt={causeName} className="w-12 h-12 rounded-2xl object-cover flex-shrink-0" />
                ) : (
                  <div className="w-12 h-12 rounded-2xl bg-primary-bg flex items-center justify-center flex-shrink-0 text-xl">❤️</div>
                )}
                <div className="flex-1 min-w-0">
                  <p className="font-extrabold text-[#2D2D2D]">{causeName}</p>
                  <p className="text-xs text-primary font-bold">{formatCurrency(donationAmount)} donados</p>
                </div>
              </div>
              {causeDescription && (
                <p className="text-sm text-muted leading-relaxed">
                  Esta donación ayuda a: {causeDescription}
                </p>
              )}
            </div>
          )}

          {/* Share button */}
          <button
            onClick={handleShare}
            className="btn w-full bg-white border-2 border-primary text-primary font-extrabold hover:bg-primary hover:text-white transition-all mb-3 flex items-center justify-center gap-2"
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4">
              <circle cx="18" cy="5" r="3" />
              <circle cx="6" cy="12" r="3" />
              <circle cx="18" cy="19" r="3" />
              <line x1="8.59" y1="13.51" x2="15.42" y2="17.49" />
              <line x1="15.41" y1="6.51" x2="8.59" y2="10.49" />
            </svg>
            Compartir mi apoyo
          </button>

          <Link href={`/pedido/${id}`} className="btn btn-primary w-full mb-3">
            Ver estado del pedido
          </Link>
          <Link href="/inicio" className="btn w-full bg-white border-2 border-border text-[#2D2D2D] font-bold hover:border-primary hover:text-primary transition-colors">
            Volver al inicio
          </Link>
        </div>
      </div>
    </div>
  )
}
