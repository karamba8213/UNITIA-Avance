'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { getUser } from '@/lib/auth'
import { api } from '@/lib/api'

function formatCurrency(n) {
  return new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(n)
}

function formatDate(d) {
  return new Intl.DateTimeFormat('es-MX', { day: '2-digit', month: 'short', year: 'numeric' }).format(new Date(d))
}

const STATUS_LABELS = {
  PENDING: { label: 'Pendiente', color: 'bg-yellow-100 text-yellow-700' },
  PAID: { label: 'Por confirmar', color: 'bg-blue-100 text-blue-700' },
  CONFIRMED: { label: 'Confirmado', color: 'bg-green-100 text-green-700' },
  DISPUTED: { label: 'En disputa', color: 'bg-red-100 text-red-700' },
}

export default function CauseDonationsPage() {
  const router = useRouter()
  const [donations, setDonations] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [confirming, setConfirming] = useState(null)
  const [proofModal, setProofModal] = useState(null)

  // Dispute modal state
  const [disputeModal, setDisputeModal] = useState(null) // donationId
  const [disputeReason, setDisputeReason] = useState('')
  const [disputing, setDisputing] = useState(false)

  useEffect(() => {
    const u = getUser()
    if (!u || u.role !== 'CAUSE') { router.push('/login'); return }

    api.donations.list()
      .then(res => setDonations(res.data?.donations || res.data || []))
      .catch(err => setError(err.message || 'Error al cargar donaciones'))
      .finally(() => setLoading(false))
  }, [])

  async function handleConfirm(id) {
    setConfirming(id)
    try {
      await api.donations.confirm(id)
      setDonations(prev => prev.map(d => d.id === id ? { ...d, status: 'CONFIRMED' } : d))
    } catch (err) {
      alert(err.message || 'Error al confirmar')
    } finally {
      setConfirming(null)
    }
  }

  async function handleDispute() {
    if (!disputeModal) return
    setDisputing(true)
    try {
      await api.donations.dispute(disputeModal, disputeReason)
      setDonations(prev => prev.map(d => d.id === disputeModal ? { ...d, status: 'DISPUTED' } : d))
      setDisputeModal(null)
      setDisputeReason('')
    } catch (err) {
      alert(err.message || 'Error al reportar disputa')
    } finally {
      setDisputing(false)
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="w-10 h-10 border-4 border-primary border-t-transparent rounded-full animate-spin" />
      </div>
    )
  }

  const totalConfirmed = donations.filter(d => d.status === 'CONFIRMED').reduce((s, d) => s + (d.amount || 0), 0)
  const totalPending = donations.filter(d => d.status === 'PAID').reduce((s, d) => s + (d.amount || 0), 0)
  const totalDisputed = donations.filter(d => d.status === 'DISPUTED').reduce((s, d) => s + (d.amount || 0), 0)
  const pendingCount = donations.filter(d => d.status === 'PAID').length

  return (
    <div className="min-h-screen bg-background pb-28">
      <nav className="bg-white border-b border-border sticky top-0 z-40" style={{ boxShadow: '0 1px 8px rgba(0,0,0,0.06)' }}>
        <div className="max-w-xl mx-auto px-4 flex items-center h-14">
          <h1 className="text-lg font-extrabold text-[#2D2D2D]">Donaciones</h1>
        </div>
      </nav>

      <main className="max-w-xl mx-auto px-4 py-6 space-y-4">
        {/* Summary cards */}
        <div className="grid grid-cols-2 gap-3">
          <div className="card text-center">
            <p className="text-2xl font-extrabold text-primary">{formatCurrency(totalConfirmed)}</p>
            <p className="text-xs text-muted font-semibold uppercase tracking-wide mt-1">Confirmado</p>
          </div>
          <div className="card text-center">
            <p className="text-2xl font-extrabold text-blue-600">{formatCurrency(totalPending)}</p>
            <p className="text-xs text-muted font-semibold uppercase tracking-wide mt-1">Por confirmar</p>
          </div>
          {totalDisputed > 0 && (
            <div className="card text-center col-span-2 border-red-100">
              <p className="text-xl font-extrabold text-red-600">{formatCurrency(totalDisputed)}</p>
              <p className="text-xs text-muted font-semibold uppercase tracking-wide mt-1">En disputa</p>
            </div>
          )}
        </div>

        {/* Alert: donations waiting for confirmation */}
        {pendingCount > 0 && (
          <div className="p-4 bg-blue-50 border border-blue-200 rounded-2xl flex items-start gap-3">
            <div className="w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center flex-shrink-0">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4 text-blue-600">
                <path strokeLinecap="round" strokeLinejoin="round" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
              </svg>
            </div>
            <div>
              <p className="text-sm font-bold text-blue-800">
                {pendingCount === 1 ? 'Hay 1 pago esperando tu confirmación' : `Hay ${pendingCount} pagos esperando tu confirmación`}
              </p>
              <p className="text-xs text-blue-600 mt-0.5">Revisa el comprobante y confirma o reporta si no recibiste el dinero.</p>
            </div>
          </div>
        )}

        {error && (
          <div className="p-4 bg-red-50 border border-red-200 rounded-2xl text-red-700 text-sm font-medium">{error}</div>
        )}

        {/* Donations list */}
        {donations.length === 0 ? (
          <div className="card text-center py-10">
            <p className="text-4xl mb-3">❤️</p>
            <p className="text-[#2D2D2D] font-bold">Aún no hay donaciones</p>
            <p className="text-muted text-sm mt-1 leading-relaxed">
              Las donaciones aparecerán aquí cuando los restaurantes marquen sus pagos.
            </p>
          </div>
        ) : (
          <div className="space-y-3">
            {donations.map(donation => {
              const statusInfo = STATUS_LABELS[donation.status] || STATUS_LABELS.PENDING
              const isPaid = donation.status === 'PAID'
              const isDisputed = donation.status === 'DISPUTED'
              return (
                <div
                  key={donation.id}
                  className={`card ${isPaid ? 'border-blue-200 border-2' : ''} ${isDisputed ? 'border-red-200 border-2' : ''}`}
                >
                  <div className="flex items-start gap-3">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1 flex-wrap">
                        <span className={`text-xs font-bold px-2.5 py-1 rounded-full ${statusInfo.color}`}>
                          {statusInfo.label}
                        </span>
                        {donation.paymentMethod && (
                          <span className="text-xs font-bold text-muted">
                            {donation.paymentMethod === 'TRANSFER' ? '🏦 Transferencia' : '💵 Efectivo'}
                          </span>
                        )}
                      </div>

                      <p className="font-extrabold text-primary text-lg">{formatCurrency(donation.amount || 0)}</p>

                      {donation.restaurant?.name && (
                        <p className="text-sm font-bold text-[#2D2D2D] mt-0.5">{donation.restaurant.name}</p>
                      )}
                      {donation.order?.createdAt && (
                        <p className="text-xs text-muted mt-0.5">{formatDate(donation.order.createdAt)}</p>
                      )}
                      {donation.notes && !isDisputed && (
                        <p className="text-xs text-muted mt-1 italic">"{donation.notes}"</p>
                      )}
                      {isDisputed && donation.notes && (
                        <p className="text-xs text-red-600 font-medium mt-1">{donation.notes}</p>
                      )}

                      {donation.proofUrl && (
                        <button
                          onClick={() => setProofModal(donation.proofUrl)}
                          className="mt-2 flex items-center gap-1.5 text-xs font-bold text-primary hover:underline"
                        >
                          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4">
                            <path strokeLinecap="round" strokeLinejoin="round" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                          </svg>
                          Ver comprobante
                        </button>
                      )}
                    </div>

                    {/* Actions for PAID donations */}
                    {isPaid && (
                      <div className="flex flex-col gap-2 flex-shrink-0 mt-0.5">
                        <button
                          onClick={() => handleConfirm(donation.id)}
                          disabled={confirming === donation.id}
                          className="btn btn-primary btn-sm"
                        >
                          {confirming === donation.id ? '...' : '✓ Ya recibí'}
                        </button>
                        <button
                          onClick={() => { setDisputeModal(donation.id); setDisputeReason('') }}
                          className="btn btn-sm border-2 border-red-200 text-red-600 hover:bg-red-50 bg-white"
                        >
                          No llegó
                        </button>
                      </div>
                    )}
                  </div>

                  {donation.proofUrl && (
                    <button onClick={() => setProofModal(donation.proofUrl)} className="mt-3 block">
                      <img
                        src={donation.proofUrl}
                        alt="Comprobante"
                        className="w-24 h-24 rounded-xl object-cover border-2 border-border hover:border-primary transition-colors"
                      />
                    </button>
                  )}
                </div>
              )
            })}
          </div>
        )}
      </main>

      {/* Dispute modal */}
      {disputeModal && (
        <div className="fixed inset-0 z-[100] flex items-end sm:items-center justify-center">
          <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={() => setDisputeModal(null)} />
          <div className="relative bg-white rounded-t-[32px] sm:rounded-2xl p-6 pb-10 w-full sm:max-w-sm shadow-2xl z-10">
            <div className="flex justify-center mb-4 sm:hidden">
              <div className="w-10 h-1 bg-border rounded-full" />
            </div>

            <div className="w-12 h-12 rounded-2xl bg-red-100 flex items-center justify-center mb-4">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-6 h-6 text-red-600">
                <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3m0 4h.01M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z" />
              </svg>
            </div>

            <h3 className="font-extrabold text-[#2D2D2D] text-lg mb-1">Reportar que no recibiste el pago</h3>
            <p className="text-sm text-muted mb-5 leading-relaxed">
              El restaurante será notificado y el equipo de Unitia revisará la disputa. Solo usa esto si realmente no recibiste el dinero.
            </p>

            <div className="mb-5">
              <label className="block text-sm font-bold text-[#2D2D2D] mb-1.5">
                ¿Por qué reportas esta disputa? <span className="text-muted font-normal">(opcional)</span>
              </label>
              <textarea
                className="input resize-none text-sm"
                rows={3}
                placeholder="Ej: Revisé mi cuenta y no hay ningún depósito en los últimos 3 días..."
                value={disputeReason}
                onChange={e => setDisputeReason(e.target.value)}
              />
            </div>

            <div className="flex gap-3">
              <button onClick={() => setDisputeModal(null)} className="btn btn-secondary flex-1 btn-sm">
                Cancelar
              </button>
              <button
                onClick={handleDispute}
                disabled={disputing}
                className="btn btn-sm flex-1 bg-red-600 text-white hover:bg-red-700 font-bold rounded-2xl disabled:opacity-50"
              >
                {disputing ? 'Enviando...' : 'Reportar disputa'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Proof fullscreen modal */}
      {proofModal && (
        <div className="fixed inset-0 z-[100] bg-black/80 flex items-center justify-center p-4" onClick={() => setProofModal(null)}>
          <div className="relative max-w-lg w-full">
            <img src={proofModal} alt="Comprobante" className="w-full rounded-2xl shadow-2xl" onClick={e => e.stopPropagation()} />
            <button
              onClick={() => setProofModal(null)}
              className="absolute top-3 right-3 w-9 h-9 rounded-full bg-white/90 flex items-center justify-center text-[#2D2D2D] shadow hover:bg-white transition-colors"
            >
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4">
                <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
              </svg>
            </button>
          </div>
        </div>
      )}

    </div>
  )
}
