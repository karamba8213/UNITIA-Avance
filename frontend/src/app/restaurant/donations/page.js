'use client'
import { useEffect, useState } from 'react'
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
  const [paying, setPaying] = useState(null)
  const [payNote, setPayNote] = useState('')
  const [showModal, setShowModal] = useState(null) // donation id

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

  async function markPaid(donationId) {
    setPaying(donationId)
    try {
      await api.donations.markPaid(donationId, payNote)
      setShowModal(null)
      setPayNote('')
      loadDonations()
    } catch (err) {
      alert(err.message)
    } finally {
      setPaying(null)
    }
  }

  const summaryMap = Object.fromEntries(summary.map(s => [s.status, s]))

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white border-b border-gray-100 px-4 sm:px-6 py-4 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Link href="/restaurant/dashboard" className="text-gray-400 hover:text-gray-600 text-sm">← Dashboard</Link>
          <span className="text-gray-200">|</span>
          <span className="font-semibold text-gray-900">Donaciones</span>
        </div>
      </header>

      <main className="max-w-4xl mx-auto px-4 sm:px-6 py-8">
        {/* Summary cards */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 mb-6">
          {['PENDING', 'PAID', 'CONFIRMED', 'DISPUTED'].map(s => (
            <div key={s} className="card text-center py-3 cursor-pointer hover:shadow-md transition-shadow" onClick={() => setFilter(s)}>
              <p className="text-lg font-bold text-gray-900">
                {formatCurrency(summaryMap[s]?._sum?.amount || 0)}
              </p>
              <p className="text-xs text-gray-500 mt-0.5">{STATUS_LABELS[s]}</p>
              {summaryMap[s]?._count > 0 && (
                <span className={`mt-1 ${STATUS_COLORS[s]}`}>{summaryMap[s]._count}</span>
              )}
            </div>
          ))}
        </div>

        {/* Filter tabs */}
        <div className="flex gap-1 mb-4 bg-white rounded-lg border border-gray-200 p-1 w-fit">
          {[{ v: '', l: 'Todas' }, { v: 'PENDING', l: 'Pendientes' }, { v: 'PAID', l: 'Pagadas' }, { v: 'CONFIRMED', l: 'Confirmadas' }].map(({ v, l }) => (
            <button
              key={v}
              onClick={() => setFilter(v)}
              className={`px-3 py-1.5 rounded-md text-sm font-medium transition-colors ${filter === v ? 'bg-primary text-white' : 'text-gray-600 hover:text-gray-900'}`}
            >
              {l}
            </button>
          ))}
        </div>

        {/* Table */}
        <div className="card p-0 overflow-hidden">
          {loading ? (
            <div className="py-12 text-center text-gray-400">Cargando...</div>
          ) : donations.length === 0 ? (
            <div className="py-12 text-center text-gray-400">No hay donaciones en este estado.</div>
          ) : (
            <div className="divide-y divide-gray-50">
              {donations.map(d => (
                <div key={d.id} className="px-5 py-4 flex items-center gap-4">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-0.5">
                      {d.cause?.logo && <img src={d.cause.logo} alt="" className="w-5 h-5 rounded-full object-cover" />}
                      <span className="font-medium text-sm text-gray-900">{d.cause?.name}</span>
                    </div>
                    <p className="text-xs text-gray-400">
                      Pedido de {d.order?.customerName} · {d.order?.createdAt && formatDate(d.order.createdAt)}
                    </p>
                    {d.notes && <p className="text-xs text-gray-500 mt-0.5">"{d.notes}"</p>}
                  </div>
                  <div className="text-right flex-shrink-0">
                    <p className="font-bold text-gray-900">{formatCurrency(d.amount)}</p>
                    <span className={STATUS_COLORS[d.status]}>{STATUS_LABELS[d.status]}</span>
                  </div>
                  {d.status === 'PENDING' && (
                    <button
                      onClick={() => setShowModal(d.id)}
                      className="btn-primary text-xs px-3 py-1.5 flex-shrink-0"
                    >
                      Marcar pagada
                    </button>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      </main>

      {/* Pay modal */}
      {showModal && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl p-6 w-full max-w-sm shadow-xl">
            <h3 className="font-bold text-gray-900 text-lg mb-2">Confirmar pago</h3>
            <p className="text-sm text-gray-500 mb-4">
              Estás marcando esta donación como pagada. La causa recibirá una notificación para confirmar.
            </p>
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">Nota (opcional)</label>
              <input
                className="input text-sm"
                placeholder="Ej: transferencia bancaria #123456"
                value={payNote}
                onChange={e => setPayNote(e.target.value)}
              />
            </div>
            <div className="flex gap-3">
              <button onClick={() => { setShowModal(null); setPayNote('') }} className="btn-secondary flex-1 text-sm">
                Cancelar
              </button>
              <button onClick={() => markPaid(showModal)} disabled={paying === showModal} className="btn-primary flex-1 text-sm">
                {paying === showModal ? 'Procesando...' : 'Confirmar pago'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
