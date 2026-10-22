'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { getUser } from '@/lib/auth'

const EXAMPLE_UPDATES = [
  {
    id: 1,
    content: '¡Gracias a todos los que nos apoyaron este mes! Logramos alimentar a 45 familias gracias a sus donaciones. 🙏',
    createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
    likes: 12,
  },
  {
    id: 2,
    content: 'Esta semana comenzamos un nuevo programa educativo con los fondos recaudados. Los niños ya están aprendiendo. 📚',
    createdAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
    likes: 8,
  },
]

function formatDate(d) {
  const diff = Date.now() - new Date(d).getTime()
  const days = Math.floor(diff / (1000 * 60 * 60 * 24))
  if (days === 0) return 'Hoy'
  if (days === 1) return 'Ayer'
  if (days < 7) return `Hace ${days} días`
  return new Intl.DateTimeFormat('es-MX', { day: '2-digit', month: 'short' }).format(new Date(d))
}

export default function CauseUpdatesPage() {
  const router = useRouter()
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)
  const [updates, setUpdates] = useState(EXAMPLE_UPDATES)
  const [newText, setNewText] = useState('')
  const [posting, setPosting] = useState(false)

  useEffect(() => {
    const u = getUser()
    if (!u || u.role !== 'CAUSE') {
      router.push('/login')
      return
    }
    setUser(u)
    setLoading(false)
  }, [])

  function handlePost(e) {
    e.preventDefault()
    if (!newText.trim()) return
    setPosting(true)
    // Simulate posting (no backend endpoint yet)
    setTimeout(() => {
      setUpdates(prev => [
        {
          id: Date.now(),
          content: newText.trim(),
          createdAt: new Date().toISOString(),
          likes: 0,
        },
        ...prev,
      ])
      setNewText('')
      setPosting(false)
    }, 600)
  }

  if (loading || !user) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="w-10 h-10 border-4 border-primary border-t-transparent rounded-full animate-spin" />
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-background pb-28">
      {/* Header */}
      <nav className="bg-white border-b border-border sticky top-0 z-40" style={{ boxShadow: '0 1px 8px rgba(0,0,0,0.06)' }}>
        <div className="max-w-xl mx-auto px-4 flex items-center h-14">
          <h1 className="text-lg font-extrabold text-[#2D2D2D]">Actualizaciones</h1>
        </div>
      </nav>

      <main className="max-w-xl mx-auto px-4 py-6 space-y-4">
        {/* Compose */}
        <form onSubmit={handlePost} className="card space-y-3">
          <h2 className="font-extrabold text-[#2D2D2D] text-sm">Nueva actualización</h2>
          <textarea
            className="input resize-none w-full"
            rows={3}
            placeholder="Contale a tus donantes cómo van las cosas..."
            value={newText}
            onChange={e => setNewText(e.target.value)}
            maxLength={500}
          />
          <div className="flex items-center justify-between gap-3">
            <button
              type="button"
              className="flex items-center gap-2 text-muted text-sm font-bold hover:text-primary transition-colors"
              title="Agregar foto (próximamente)"
              onClick={() => alert('Subida de fotos próximamente')}
            >
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-5 h-5">
                <rect x="3" y="3" width="18" height="18" rx="2" ry="2" />
                <circle cx="8.5" cy="8.5" r="1.5" />
                <polyline points="21 15 16 10 5 21" />
              </svg>
              Foto
            </button>
            <div className="flex items-center gap-3">
              <span className="text-xs text-muted">{newText.length}/500</span>
              <button
                type="submit"
                disabled={posting || !newText.trim()}
                className="btn btn-primary btn-sm px-5"
              >
                {posting ? 'Publicando...' : 'Publicar'}
              </button>
            </div>
          </div>
        </form>

        {/* Coming soon note */}
        <div className="flex items-center gap-2 p-3 bg-primary-bg rounded-2xl border border-primary/20">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4 text-primary flex-shrink-0">
            <circle cx="12" cy="12" r="10" />
            <line x1="12" y1="8" x2="12" y2="12" />
            <line x1="12" y1="16" x2="12.01" y2="16" />
          </svg>
          <p className="text-xs text-primary font-bold">
            Las actualizaciones publicadas serán visibles en el perfil de tu causa próximamente.
          </p>
        </div>

        {/* Updates list */}
        <div className="space-y-3">
          {updates.map(update => (
            <div key={update.id} className="card">
              <div className="flex items-start justify-between gap-2 mb-3">
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 rounded-full bg-primary flex items-center justify-center flex-shrink-0">
                    <svg viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth={2} className="w-4 h-4">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
                      <circle cx="12" cy="7" r="4" />
                    </svg>
                  </div>
                  <div>
                    <p className="text-xs font-extrabold text-[#2D2D2D]">{user.name}</p>
                    <p className="text-xs text-muted">{formatDate(update.createdAt)}</p>
                  </div>
                </div>
              </div>
              <p className="text-sm text-[#2D2D2D] leading-relaxed whitespace-pre-wrap">{update.content}</p>
              <div className="flex items-center gap-1 mt-3 pt-3 border-t border-border">
                <button className="flex items-center gap-1.5 text-xs text-muted font-bold hover:text-primary transition-colors">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
                  </svg>
                  {update.likes > 0 ? update.likes : ''} Me gusta
                </button>
              </div>
            </div>
          ))}
        </div>
      </main>

    </div>
  )
}
