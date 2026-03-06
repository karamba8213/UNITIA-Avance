'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { api } from '@/lib/api'
import { getUser, clearTokens } from '@/lib/auth'

export default function RestaurantSettingsPage() {
  const router = useRouter()
  const user = typeof window !== 'undefined' ? getUser() : null
  const [form, setForm] = useState({ name: '', description: '', address: '', phone: '', logo: '', donationPercentage: 5, causeId: '' })
  const [causes, setCauses] = useState([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [saved, setSaved] = useState(false)
  const [error, setError] = useState('')
  const [restaurantSlug, setRestaurantSlug] = useState('')

  useEffect(() => {
    if (!user || user.role !== 'RESTAURANT') { router.push('/login'); return }
    Promise.all([api.restaurant.getProfile(), api.cause.list()])
      .then(([profileRes, causesRes]) => {
        const p = profileRes.data
        setRestaurantSlug(p.slug)
        setForm({
          name: p.name || '',
          description: p.description || '',
          address: p.address || '',
          phone: p.phone || '',
          logo: p.logo || '',
          donationPercentage: p.donationPercentage || 5,
          causeId: p.causeId || '',
        })
        setCauses(causesRes.data || [])
      })
      .catch(err => { if (err.status === 401) { clearTokens(); router.push('/login') } })
      .finally(() => setLoading(false))
  }, [])

  async function handleSave(e) {
    e.preventDefault()
    setSaving(true)
    setError('')
    setSaved(false)
    try {
      await api.restaurant.updateProfile({
        ...form,
        donationPercentage: parseFloat(form.donationPercentage),
        causeId: form.causeId || null,
        logo: form.logo || undefined,
      })
      setSaved(true)
      setTimeout(() => setSaved(false), 3000)
    } catch (err) {
      setError(err.message)
    } finally {
      setSaving(false)
    }
  }

  if (loading) return <div className="min-h-screen flex items-center justify-center"><div className="text-gray-400">Cargando...</div></div>

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white border-b border-gray-100 px-4 sm:px-6 py-4 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Link href="/restaurant/dashboard" className="text-gray-400 hover:text-gray-600 text-sm">← Dashboard</Link>
          <span className="text-gray-200">|</span>
          <span className="font-semibold text-gray-900">Configuración</span>
        </div>
        {restaurantSlug && (
          <Link href={`/r/${restaurantSlug}`} target="_blank" className="text-xs text-primary hover:underline">
            Ver mi página pública →
          </Link>
        )}
      </header>

      <main className="max-w-2xl mx-auto px-4 sm:px-6 py-8">
        {saved && (
          <div className="mb-4 p-3 bg-green-50 border border-green-200 rounded-lg text-green-700 text-sm">
            Cambios guardados correctamente.
          </div>
        )}
        {error && (
          <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">{error}</div>
        )}

        <form onSubmit={handleSave} className="space-y-6">
          <div className="card space-y-4">
            <h2 className="font-semibold text-gray-900">Perfil del restaurante</h2>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Nombre</label>
              <input className="input" value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} required />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Descripción</label>
              <textarea className="input resize-none" rows={2} value={form.description} onChange={e => setForm(f => ({ ...f, description: e.target.value }))} />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Dirección</label>
              <input className="input" value={form.address} onChange={e => setForm(f => ({ ...f, address: e.target.value }))} />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Teléfono</label>
              <input type="tel" className="input" value={form.phone} onChange={e => setForm(f => ({ ...f, phone: e.target.value }))} />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Logo (URL)</label>
              <input type="url" className="input" placeholder="https://..." value={form.logo} onChange={e => setForm(f => ({ ...f, logo: e.target.value }))} />
            </div>
          </div>

          <div className="card space-y-4">
            <h2 className="font-semibold text-gray-900">Causa y donación</h2>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Causa que apoyás
              </label>
              <select
                className="input"
                value={form.causeId}
                onChange={e => setForm(f => ({ ...f, causeId: e.target.value }))}
              >
                <option value="">— Sin causa seleccionada —</option>
                {causes.map(c => (
                  <option key={c.id} value={c.id}>{c.name}</option>
                ))}
              </select>
              {form.causeId && (
                <Link href={`/c/${causes.find(c => c.id === form.causeId)?.slug}`} target="_blank" className="text-xs text-primary hover:underline mt-1 inline-block">
                  Ver página de la causa →
                </Link>
              )}
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Porcentaje de donación por pedido
              </label>
              <div className="flex items-center gap-3">
                <input
                  type="number"
                  className="input w-28"
                  min="0"
                  max="100"
                  step="0.5"
                  value={form.donationPercentage}
                  onChange={e => setForm(f => ({ ...f, donationPercentage: e.target.value }))}
                />
                <span className="text-gray-500 text-sm">% de cada pedido</span>
              </div>
              <p className="text-xs text-gray-400 mt-1">
                En un pedido de $1,000, donarías ${(1000 * form.donationPercentage / 100).toFixed(2)}.
              </p>
            </div>
          </div>

          <button type="submit" disabled={saving} className="btn-primary w-full py-3">
            {saving ? 'Guardando...' : 'Guardar cambios'}
          </button>
        </form>
      </main>
    </div>
  )
}
