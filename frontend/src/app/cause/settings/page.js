'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { api } from '@/lib/api'
import { getUser, clearTokens } from '@/lib/auth'

export default function CauseSettingsPage() {
  const router = useRouter()
  const user = typeof window !== 'undefined' ? getUser() : null
  const [form, setForm] = useState({ name: '', description: '', story: '', logo: '', targetAmount: 0, images: [] })
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

  if (loading) return <div className="min-h-screen flex items-center justify-center"><div className="text-gray-400">Cargando...</div></div>

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white border-b border-gray-100 px-4 sm:px-6 py-4 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Link href="/cause/dashboard" className="text-gray-400 hover:text-gray-600 text-sm">← Dashboard</Link>
          <span className="text-gray-200">|</span>
          <span className="font-semibold text-gray-900">Configuración</span>
        </div>
        {causeSlug && (
          <Link href={`/c/${causeSlug}`} target="_blank" className="text-xs text-primary hover:underline">
            Ver página pública →
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
            <h2 className="font-semibold text-gray-900">Identidad de la causa</h2>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Nombre de la organización</label>
              <input className="input" value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} required />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Descripción breve <span className="text-gray-400">(se muestra en la landing)</span></label>
              <textarea className="input resize-none" rows={2} value={form.description} onChange={e => setForm(f => ({ ...f, description: e.target.value }))} />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Logo (URL)</label>
              <input type="url" className="input" placeholder="https://..." value={form.logo} onChange={e => setForm(f => ({ ...f, logo: e.target.value }))} />
            </div>
          </div>

          <div className="card space-y-4">
            <h2 className="font-semibold text-gray-900">Historia y contenido</h2>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Historia completa <span className="text-gray-400">(aparece en tu página pública)</span>
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
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Objetivo de recaudación
              </label>
              <div className="flex items-center gap-2">
                <span className="text-gray-500 text-sm">$</span>
                <input
                  type="number"
                  className="input"
                  min="0"
                  value={form.targetAmount}
                  onChange={e => setForm(f => ({ ...f, targetAmount: e.target.value }))}
                />
              </div>
              <p className="text-xs text-gray-400 mt-1">Dejá en 0 si no querés mostrar un objetivo.</p>
            </div>
          </div>

          <div className="card space-y-4">
            <h2 className="font-semibold text-gray-900">Fotos</h2>
            <div className="grid grid-cols-2 gap-2">
              {form.images.map((img, idx) => (
                <div key={idx} className="relative">
                  <img src={img} alt="" className="w-full h-28 object-cover rounded-lg" />
                  <button
                    type="button"
                    onClick={() => removeImage(idx)}
                    className="absolute top-1 right-1 w-6 h-6 bg-red-500 text-white rounded-full text-xs flex items-center justify-center"
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
              <button type="button" onClick={addImage} className="btn-secondary text-sm px-4">Agregar</button>
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
