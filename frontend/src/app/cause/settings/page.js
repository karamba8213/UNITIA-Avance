'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { api } from '@/lib/api'
import { getUser, clearTokens } from '@/lib/auth'

export default function CauseSettingsPage() {
  const router = useRouter()
  const user = typeof window !== 'undefined' ? getUser() : null
  const [form, setForm] = useState({
    name: '', description: '', story: '', logo: '', targetAmount: 0, images: [],
    bankName: '', bankHolder: '', bankClabe: '', bankAccount: '',
  })
  const [causeSlug, setCauseSlug] = useState('')
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [saved, setSaved] = useState(false)
  const [error, setError] = useState('')
  const [newImage, setNewImage] = useState('')

  useEffect(() => {
    if (!user || user.role !== 'CAUSE') { router.push('/login'); return }
    api.cause.getProfile()
      .then(res => {
        const p = res.data
        setCauseSlug(p.slug)
        setForm({
          name: p.name || '',
          description: p.description || '',
          story: p.story || '',
          logo: p.logo || '',
          targetAmount: p.targetAmount || 0,
          images: p.images || [],
          bankName: p.bankName || '',
          bankHolder: p.bankHolder || '',
          bankClabe: p.bankClabe || '',
          bankAccount: p.bankAccount || '',
        })
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
      await api.cause.updateProfile({
        ...form,
        targetAmount: parseFloat(form.targetAmount) || 0,
        logo: form.logo || undefined,
        bankName: form.bankName || undefined,
        bankHolder: form.bankHolder || undefined,
        bankClabe: form.bankClabe || undefined,
        bankAccount: form.bankAccount || undefined,
      })
      setSaved(true)
      setTimeout(() => setSaved(false), 3000)
    } catch (err) {
      setError(err.message)
    } finally {
      setSaving(false)
    }
  }

  function addImage() {
    if (!newImage.trim()) return
    setForm(f => ({ ...f, images: [...f.images, newImage.trim()] }))
    setNewImage('')
  }

  function removeImage(idx) {
    setForm(f => ({ ...f, images: f.images.filter((_, i) => i !== idx) }))
  }

  if (loading) return (
    <div className="min-h-screen flex items-center justify-center bg-background">
      <div className="w-10 h-10 border-3 border-primary border-t-transparent rounded-full animate-spin" />
    </div>
  )

  const hasBankInfo = form.bankClabe || form.bankAccount

  return (
    <div className="min-h-screen bg-background pb-28">
      <header className="bg-white border-b border-border sticky top-0 z-10 px-4 py-4 flex items-center gap-3" style={{ boxShadow: '0 1px 8px rgba(0,0,0,0.06)' }}>
        <Link href="/cause/dashboard" className="w-9 h-9 rounded-xl border border-border flex items-center justify-center text-muted hover:text-primary transition-colors">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4">
            <polyline points="15 18 9 12 15 6" />
          </svg>
        </Link>
        <h1 className="font-extrabold text-[#2D2D2D] flex-1">Configuración</h1>
        {causeSlug && (
          <Link href={`/c/${causeSlug}`} target="_blank" className="text-xs text-primary font-bold hover:underline">
            Ver página →
          </Link>
        )}
      </header>

      <main className="max-w-2xl mx-auto px-4 py-6">
        {saved && (
          <div className="mb-4 p-4 bg-green-50 border border-green-200 rounded-2xl text-green-700 text-sm font-bold">
            ✓ Cambios guardados correctamente.
          </div>
        )}
        {error && (
          <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded-2xl text-red-700 text-sm font-medium">{error}</div>
        )}

        <form onSubmit={handleSave} className="space-y-4">
          <div className="card space-y-4">
            <h2 className="font-extrabold text-[#2D2D2D]">Identidad de la causa</h2>
            <div>
              <label className="block text-sm font-bold text-[#2D2D2D] mb-1.5">Nombre de la organización</label>
              <input className="input" value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} required />
            </div>
            <div>
              <label className="block text-sm font-bold text-[#2D2D2D] mb-1.5">
                Descripción breve <span className="text-muted font-normal">(se muestra en la landing)</span>
              </label>
              <textarea className="input resize-none" rows={2} value={form.description} onChange={e => setForm(f => ({ ...f, description: e.target.value }))} />
            </div>
            <div>
              <label className="block text-sm font-bold text-[#2D2D2D] mb-1.5">Logo (URL)</label>
              <input type="url" className="input" placeholder="https://..." value={form.logo} onChange={e => setForm(f => ({ ...f, logo: e.target.value }))} />
            </div>
          </div>

          {/* DATOS BANCARIOS */}
          <div className="card space-y-4">
            <div className="flex items-center justify-between">
              <h2 className="font-extrabold text-[#2D2D2D]">Datos bancarios para donaciones</h2>
              {hasBankInfo && (
                <span className="text-xs font-bold text-green-600 bg-green-50 px-2.5 py-1 rounded-full">Configurado ✓</span>
              )}
            </div>
            <p className="text-xs text-muted leading-relaxed -mt-1">
              Los restaurantes verán estos datos al marcar que transfirieron una donación. Así saben exactamente a qué cuenta depositar.
            </p>

            {!hasBankInfo && (
              <div className="p-3 bg-amber-50 border border-amber-200 rounded-2xl text-amber-700 text-xs font-medium flex items-start gap-2">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4 flex-shrink-0 mt-0.5">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3m0 4h.01M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z" />
                </svg>
                Sin datos bancarios los restaurantes no sabrán a dónde transferir las donaciones.
              </div>
            )}

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-sm font-bold text-[#2D2D2D] mb-1.5">Banco</label>
                <input
                  className="input"
                  placeholder="Ej: BBVA, Santander..."
                  value={form.bankName}
                  onChange={e => setForm(f => ({ ...f, bankName: e.target.value }))}
                />
              </div>
              <div>
                <label className="block text-sm font-bold text-[#2D2D2D] mb-1.5">Titular de la cuenta</label>
                <input
                  className="input"
                  placeholder="Nombre completo"
                  value={form.bankHolder}
                  onChange={e => setForm(f => ({ ...f, bankHolder: e.target.value }))}
                />
              </div>
            </div>
            <div>
              <label className="block text-sm font-bold text-[#2D2D2D] mb-1.5">
                CLABE interbancaria <span className="text-muted font-normal">(18 dígitos)</span>
              </label>
              <input
                className="input font-mono tracking-wider"
                placeholder="000000000000000000"
                maxLength={18}
                value={form.bankClabe}
                onChange={e => setForm(f => ({ ...f, bankClabe: e.target.value.replace(/\D/g, '') }))}
              />
            </div>
            <div>
              <label className="block text-sm font-bold text-[#2D2D2D] mb-1.5">
                Número de cuenta <span className="text-muted font-normal">(opcional)</span>
              </label>
              <input
                className="input font-mono"
                placeholder="Número de cuenta alternativo"
                value={form.bankAccount}
                onChange={e => setForm(f => ({ ...f, bankAccount: e.target.value }))}
              />
            </div>
          </div>

          <div className="card space-y-4">
            <h2 className="font-extrabold text-[#2D2D2D]">Historia y contenido</h2>
            <div>
              <label className="block text-sm font-bold text-[#2D2D2D] mb-1.5">
                Historia completa <span className="text-muted font-normal">(aparece en tu página pública)</span>
              </label>
              <textarea
                className="input resize-none"
                rows={8}
                placeholder="Contá quiénes son, qué hacen, por qué importa..."
                value={form.story}
                onChange={e => setForm(f => ({ ...f, story: e.target.value }))}
              />
            </div>
            <div>
              <label className="block text-sm font-bold text-[#2D2D2D] mb-1.5">Objetivo de recaudación</label>
              <div className="flex items-center gap-2">
                <span className="text-muted font-semibold">$</span>
                <input
                  type="number"
                  className="input"
                  min="0"
                  value={form.targetAmount}
                  onChange={e => setForm(f => ({ ...f, targetAmount: e.target.value }))}
                />
              </div>
              <p className="text-xs text-muted mt-1.5">Deja en 0 si no quieres mostrar un objetivo.</p>
            </div>
          </div>

          <div className="card space-y-4">
            <h2 className="font-extrabold text-[#2D2D2D]">Fotos</h2>
            <div className="grid grid-cols-2 gap-2">
              {form.images.map((img, idx) => (
                <div key={idx} className="relative">
                  <img src={img} alt="" className="w-full h-28 object-cover rounded-2xl" />
                  <button
                    type="button"
                    onClick={() => removeImage(idx)}
                    className="absolute top-2 right-2 w-7 h-7 bg-red-500 text-white rounded-full text-sm flex items-center justify-center font-bold shadow"
                  >
                    ×
                  </button>
                </div>
              ))}
            </div>
            <div className="flex gap-2">
              <input
                type="url"
                className="input flex-1 text-sm"
                placeholder="https://... (URL de imagen)"
                value={newImage}
                onChange={e => setNewImage(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && (e.preventDefault(), addImage())}
              />
              <button type="button" onClick={addImage} className="btn btn-secondary btn-sm px-4">Agregar</button>
            </div>
          </div>

          <button type="submit" disabled={saving} className="btn btn-primary w-full">
            {saving ? 'Guardando...' : 'Guardar cambios'}
          </button>
        </form>
      </main>

    </div>
  )
}
