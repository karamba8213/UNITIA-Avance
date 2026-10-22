'use client'
import { useEffect, useState, useRef } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { api } from '@/lib/api'
import { getUser, clearTokens, formatCurrency, formatDate } from '@/lib/auth'

const STATUS_LABELS = {
  PENDING: 'Pendiente',
  PAID: 'Pagada',
  CONFIRMED: 'Confirmada',
  DISPUTED: 'En disputa',
}

const STATUS_COLORS = {
  PENDING: 'badge-pending',
  PAID: 'badge-paid',
  CONFIRMED: 'badge-confirmed',
  DISPUTED: 'badge-disputed',
}

export default function RestaurantDonationsPage() {
  const router = useRouter()
  const user = typeof window !== 'undefined' ? getUser() : null
  const [donations, setDonations] = useState([])
  const [summary, setSummary] = useState([])
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState('PENDING')

  // Modal state
  const [showModal, setShowModal] = useState(null) // donationId
  const [modalDonation, setModalDonation] = useState(null) // full donation object
  const [payMethod, setPayMethod] = useState('CASH')
  const [payNote, setPayNote] = useState('')
  const [proofFile, setProofFile] = useState(null)
  const [paying, setPaying] = useState(false)
  const fileInputRef = useRef(null)

  useEffect(() => {
    if (!user || user.role !== 'RESTAURANT') { router.push('/login'); return }
    loadDonations()
  }, [filter])

  async function loadDonations() {
    setLoading(true)
    try {
      const res = await api.donations.list({ status: filter || '', limit: 50 })
      setDonations(res.data.donations || [])
      setSummary(res.data.summary || [])
    } catch (err) {
      if (err.status === 401) { clearTokens(); router.push('/login') }
    } finally {
      setLoading(false)
    }
  }

  function openModal(donation) {
    setShowModal(donation.id)
    setModalDonation(donation)
    setPayMethod('CASH')
    setPayNote('')
    setProofFile(null)
  }

  function closeModal() {
    setShowModal(null)
    setModalDonation(null)
    setPayMethod('CASH')
    setPayNote('')
    setProofFile(null)
  }

  function handleFileChange(e) {
    const file = e.target.files?.[0]
    if (!file) return
    const reader = new FileReader()
    reader.onload = (ev) => setProofFile({ dataUrl: ev.target.result, name: file.name })
    reader.readAsDataURL(file)
  }

  async function markPaid() {
    if (payMethod === 'TRANSFER' && !proofFile) {
      alert('Por favor adjunta el comprobante de transferencia.')
      return
    }
    setPaying(true)
    try {
      await api.donations.markPaid(showModal, {
        notes: payNote || undefined,
        paymentMethod: payMethod,
        proofUrl: proofFile?.dataUrl || undefined,
      })
      closeModal()
      loadDonations()
    } catch (err) {
      alert(err.message)
    } finally {
      setPaying(false)
    }
  }

  const summaryMap = Object.fromEntries(summary.map(s => [s.status, s]))
  const pendingTotal = summaryMap['PENDING']?._sum?.amount || 0
  const pendingCount = summaryMap['PENDING']?._count || 0
  const disputedCount = summaryMap['DISPUTED']?._count || 0

  const cause = modalDonation?.cause
  const hasBankInfo = cause?.bankClabe || cause?.bankAccount

  return (
    <div className="min-h-screen bg-background pb-28">
      <header className="bg-white border-b border-border sticky top-0 z-10 px-4 py-4 flex items-center gap-3" style={{ boxShadow: '0 1px 8px rgba(0,0,0,0.06)' }}>
        <Link href="/restaurant/dashboard" className="w-9 h-9 rounded-xl border border-border flex items-center justify-center text-muted hover:text-primary transition-colors">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4">
            <polyline points="15 18 9 12 15 6" />
          </svg>
        </Link>
        <h1 className="font-extrabold text-[#2D2D2D]">Donaciones</h1>
      </header>

      <main className="max-w-2xl mx-auto px-4 py-6">
        {/* Urgent pending alert */}
        {pendingCount > 0 && (
          <div className="mb-5 p-4 bg-amber-50 border-2 border-amber-200 rounded-2xl flex items-start gap-3">
            <div className="w-10 h-10 rounded-2xl bg-amber-100 flex items-center justify-center flex-shrink-0">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-5 h-5 text-amber-600">
                <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3m0 4h.01M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z" />
              </svg>
            </div>
            <div className="flex-1">
              <p className="font-extrabold text-amber-800 text-sm">
                Tenés {formatCurrency(pendingTotal)} en donaciones pendientes de pagar
              </p>
              <p className="text-xs text-amber-600 mt-0.5 leading-relaxed">
                {pendingCount === 1 ? '1 donación espera' : `${pendingCount} donaciones esperan`} que confirmes el pago a la causa. Hacelo lo antes posible.
              </p>
            </div>
          </div>
        )}

        {/* Disputed alert */}
        {disputedCount > 0 && (
          <div className="mb-5 p-4 bg-red-50 border-2 border-red-200 rounded-2xl flex items-start gap-3">
            <div className="w-10 h-10 rounded-2xl bg-red-100 flex items-center justify-center flex-shrink-0">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-5 h-5 text-red-600">
                <circle cx="12" cy="12" r="10" /><line x1="12" y1="8" x2="12" y2="12" /><line x1="12" y1="16" x2="12.01" y2="16" />
              </svg>
            </div>
            <div className="flex-1">
              <p className="font-extrabold text-red-800 text-sm">
                {disputedCount === 1 ? 'La causa reportó 1 pago no recibido' : `La causa reportó ${disputedCount} pagos no recibidos`}
              </p>
              <p className="text-xs text-red-600 mt-0.5">Revisa las donaciones en disputa y contacta al equipo de Unitia.</p>
            </div>
          </div>
        )}

        {/* Summary cards */}
        <div className="grid grid-cols-2 gap-3 mb-6">
          {['PENDING', 'PAID', 'CONFIRMED', 'DISPUTED'].map(s => (
            <button
              key={s}
              onClick={() => setFilter(s)}
              className={`card text-center py-4 transition-all active:scale-[0.98] ${filter === s ? 'border-primary border-2' : ''}`}
            >
              <p className="text-lg font-extrabold text-[#2D2D2D]">
                {formatCurrency(summaryMap[s]?._sum?.amount || 0)}
              </p>
              <p className="text-xs text-muted mt-0.5 font-semibold">{STATUS_LABELS[s]}</p>
              {summaryMap[s]?._count > 0 && (
                <span className={`mt-1.5 ${STATUS_COLORS[s]}`}>{summaryMap[s]._count}</span>
              )}
            </button>
          ))}
        </div>

        {/* Filter tabs */}
        <div className="flex gap-1 mb-4 bg-white rounded-2xl border-2 border-border p-1">
          {[{ v: '', l: 'Todas' }, { v: 'PENDING', l: 'Pendientes' }, { v: 'PAID', l: 'Pagadas' }, { v: 'CONFIRMED', l: 'Confirmadas' }].map(({ v, l }) => (
            <button
              key={v}
              onClick={() => setFilter(v)}
              className={`flex-1 px-2 py-2.5 rounded-xl text-xs font-bold transition-colors ${filter === v ? 'bg-primary text-white' : 'text-muted hover:text-[#2D2D2D]'}`}
            >
              {l}
            </button>
          ))}
        </div>

        {/* List */}
        <div className="card p-0 overflow-hidden">
          {loading ? (
            <div className="py-12 text-center text-muted font-medium">Cargando...</div>
          ) : donations.length === 0 ? (
            <div className="py-12 text-center">
              <p className="text-3xl mb-3">💚</p>
              <p className="text-muted font-medium">No hay donaciones en este estado.</p>
            </div>
          ) : (
            <div className="divide-y divide-border">
              {donations.map(d => (
                <div key={d.id} className={`px-5 py-4 ${d.status === 'DISPUTED' ? 'bg-red-50/50' : ''}`}>
                  <div className="flex items-center gap-4">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-0.5">
                        {d.cause?.logo && <img src={d.cause.logo} alt="" className="w-5 h-5 rounded-full object-cover" />}
                        <span className="font-bold text-sm text-[#2D2D2D]">{d.cause?.name}</span>
                      </div>
                      <p className="text-xs text-muted">
                        {d.order?.customerName} · {d.order?.createdAt && formatDate(d.order.createdAt)}
                      </p>
                      {d.notes && <p className={`text-xs mt-0.5 italic ${d.status === 'DISPUTED' ? 'text-red-600 font-medium not-italic' : 'text-muted'}`}>"{d.notes}"</p>}
                      {(d.status === 'PAID' || d.status === 'CONFIRMED') && d.paymentMethod && (
                        <span className="inline-flex items-center gap-1 text-xs font-bold text-muted mt-1">
                          {d.paymentMethod === 'TRANSFER' ? (
                            <><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-3 h-3"><path strokeLinecap="round" strokeLinejoin="round" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"/></svg> Transferencia</>
                          ) : (
                            <><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-3 h-3"><path strokeLinecap="round" strokeLinejoin="round" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"/></svg> Efectivo</>
                          )}
                        </span>
                      )}
                    </div>
                    <div className="text-right flex-shrink-0">
                      <p className="font-extrabold text-[#2D2D2D]">{formatCurrency(d.amount)}</p>
                      <span className={STATUS_COLORS[d.status]}>{STATUS_LABELS[d.status]}</span>
                    </div>
                    {d.status === 'PENDING' && (
                      <button
                        onClick={() => openModal(d)}
                        className="btn btn-primary btn-sm flex-shrink-0"
                      >
                        Ya pagué
                      </button>
                    )}
                  </div>
                  {(d.status === 'PAID' || d.status === 'CONFIRMED') && d.proofUrl && (
                    <div className="mt-3">
                      <a href={d.proofUrl} target="_blank" rel="noopener noreferrer">
                        <img src={d.proofUrl} alt="Comprobante" className="w-20 h-20 rounded-xl object-cover border-2 border-border hover:border-primary transition-colors cursor-pointer" />
                      </a>
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      </main>

      {/* Pay modal */}
      {showModal && (
        <div className="fixed inset-0 z-[100] flex items-end sm:items-center justify-center">
          <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={closeModal} />
          <div className="relative bg-white rounded-t-[32px] sm:rounded-2xl p-6 pb-10 w-full sm:max-w-sm shadow-2xl z-10 max-h-[90vh] overflow-y-auto">
            <div className="flex justify-center mb-4 sm:hidden">
              <div className="w-10 h-1 bg-border rounded-full" />
            </div>

            <h3 className="font-extrabold text-[#2D2D2D] text-lg mb-1">Confirmar pago de donación</h3>
            <p className="text-sm text-muted mb-4 leading-relaxed">
              La causa recibirá una notificación para confirmar que llegó el dinero.
            </p>

            {/* Bank info for the cause */}
            {cause && (
              <div className={`mb-5 p-4 rounded-2xl border-2 ${hasBankInfo ? 'bg-primary-bg border-primary/20' : 'bg-amber-50 border-amber-200'}`}>
                <div className="flex items-center gap-2 mb-2">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className={`w-4 h-4 flex-shrink-0 ${hasBankInfo ? 'text-primary' : 'text-amber-600'}`}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
                  </svg>
                  <span className={`text-xs font-extrabold uppercase tracking-wide ${hasBankInfo ? 'text-primary' : 'text-amber-700'}`}>
                    Datos bancarios — {cause.name}
                  </span>
                </div>
                {hasBankInfo ? (
                  <div className="space-y-1.5">
                    {cause.bankName && (
                      <div className="flex justify-between items-center">
                        <span className="text-xs text-muted font-medium">Banco</span>
                        <span className="text-xs font-bold text-[#2D2D2D]">{cause.bankName}</span>
                      </div>
                    )}
                    {cause.bankHolder && (
                      <div className="flex justify-between items-center">
                        <span className="text-xs text-muted font-medium">Titular</span>
                        <span className="text-xs font-bold text-[#2D2D2D]">{cause.bankHolder}</span>
                      </div>
                    )}
                    {cause.bankClabe && (
                      <div className="flex justify-between items-center gap-2">
                        <span className="text-xs text-muted font-medium flex-shrink-0">CLABE</span>
                        <span className="text-xs font-bold text-[#2D2D2D] font-mono tracking-wider break-all text-right">{cause.bankClabe}</span>
                      </div>
                    )}
                    {cause.bankAccount && !cause.bankClabe && (
                      <div className="flex justify-between items-center">
                        <span className="text-xs text-muted font-medium">Cuenta</span>
                        <span className="text-xs font-bold text-[#2D2D2D] font-mono">{cause.bankAccount}</span>
                      </div>
                    )}
                  </div>
                ) : (
                  <p className="text-xs text-amber-700 leading-relaxed">
                    Esta causa aún no configuró sus datos bancarios. Contáctalos directamente para coordinar el pago.
                  </p>
                )}
              </div>
            )}

            {/* Payment method selector */}
            <div className="mb-4">
              <label className="block text-sm font-bold text-[#2D2D2D] mb-2">¿Cómo pagaste?</label>
              <div className="grid grid-cols-2 gap-2">
                <button
                  onClick={() => setPayMethod('CASH')}
                  className={`flex flex-col items-center gap-1.5 p-3 rounded-2xl border-2 transition-all ${payMethod === 'CASH' ? 'border-primary bg-primary-bg' : 'border-border hover:border-primary/40'}`}
                >
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className={`w-6 h-6 ${payMethod === 'CASH' ? 'text-primary' : 'text-muted'}`}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"/>
                  </svg>
                  <span className={`text-xs font-bold ${payMethod === 'CASH' ? 'text-primary' : 'text-muted'}`}>Efectivo</span>
                </button>
                <button
                  onClick={() => setPayMethod('TRANSFER')}
                  className={`flex flex-col items-center gap-1.5 p-3 rounded-2xl border-2 transition-all ${payMethod === 'TRANSFER' ? 'border-primary bg-primary-bg' : 'border-border hover:border-primary/40'}`}
                >
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className={`w-6 h-6 ${payMethod === 'TRANSFER' ? 'text-primary' : 'text-muted'}`}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"/>
                  </svg>
                  <span className={`text-xs font-bold ${payMethod === 'TRANSFER' ? 'text-primary' : 'text-muted'}`}>Transferencia</span>
                </button>
              </div>
            </div>

            {/* Transfer proof upload */}
            {payMethod === 'TRANSFER' && (
              <div className="mb-4">
                <label className="block text-sm font-bold text-[#2D2D2D] mb-2">
                  Comprobante <span className="text-red-500">*</span>
                </label>
                <input ref={fileInputRef} type="file" accept="image/*" onChange={handleFileChange} className="hidden" />
                {proofFile ? (
                  <div className="relative w-full">
                    <img src={proofFile.dataUrl} alt="Comprobante" className="w-full h-36 object-cover rounded-2xl border-2 border-primary" />
                    <button
                      onClick={() => { setProofFile(null); fileInputRef.current.value = '' }}
                      className="absolute top-2 right-2 w-7 h-7 rounded-full bg-white border border-border flex items-center justify-center text-muted hover:text-red-500 shadow"
                    >
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-3.5 h-3.5">
                        <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
                      </svg>
                    </button>
                  </div>
                ) : (
                  <button
                    onClick={() => fileInputRef.current?.click()}
                    className="w-full h-32 rounded-2xl border-2 border-dashed border-primary/40 flex flex-col items-center justify-center gap-2 hover:border-primary hover:bg-primary-bg/40 transition-all"
                  >
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.5} className="w-8 h-8 text-primary/60">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                    </svg>
                    <span className="text-xs font-bold text-primary">Subir comprobante</span>
                  </button>
                )}
              </div>
            )}

            {/* Optional note */}
            <div className="mb-5">
              <label className="block text-sm font-bold text-[#2D2D2D] mb-1.5">Nota (opcional)</label>
              <input
                className="input text-sm"
                placeholder={payMethod === 'TRANSFER' ? 'Ej: SPEI BBVA referencia #123456' : 'Ej: Entregué efectivo a la coordinadora'}
                value={payNote}
                onChange={e => setPayNote(e.target.value)}
              />
            </div>

            <div className="flex gap-3">
              <button onClick={closeModal} className="btn btn-secondary flex-1 btn-sm">Cancelar</button>
              <button
                onClick={markPaid}
                disabled={paying || (payMethod === 'TRANSFER' && !proofFile)}
                className="btn btn-primary flex-1 btn-sm disabled:opacity-50"
              >
                {paying ? 'Enviando...' : 'Confirmar pago'}
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  )
}
