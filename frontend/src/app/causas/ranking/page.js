import Link from 'next/link'

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api/v1'

async function getCauses() {
  try {
    const res = await fetch(`${API_URL}/public/causes`, { next: { revalidate: 60 } })
    const data = await res.json()
    return data.success ? data.data : []
  } catch {
    return []
  }
}

function formatCurrency(n) {
  return new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(n)
}

export const metadata = {
  title: 'Ranking de Causas — Unitia',
  description: 'Las causas que más apoyo han recibido en Unitia',
}

const MEDALS = ['🥇', '🥈', '🥉']

export default async function CausasRankingPage() {
  const causes = await getCauses()
  const sorted = [...causes].sort((a, b) => (b.totalRaised || 0) - (a.totalRaised || 0))
  const maxRaised = sorted[0]?.totalRaised || 1

  return (
    <div className="min-h-screen bg-background pb-10">
      {/* Nav */}
      <nav className="bg-white border-b border-border sticky top-0 z-40" style={{ boxShadow: '0 1px 8px rgba(0,0,0,0.06)' }}>
        <div className="max-w-2xl mx-auto px-4 flex items-center h-14 gap-3">
          <Link href="/causas" className="text-muted hover:text-primary transition-colors">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-5 h-5">
              <path strokeLinecap="round" strokeLinejoin="round" d="M19 12H5m7-7-7 7 7 7" />
            </svg>
          </Link>
          <h1 className="text-lg font-extrabold text-[#2D2D2D]">Ranking de causas</h1>
        </div>
      </nav>

      <main className="max-w-2xl mx-auto px-4 py-6">
        <div className="mb-6 text-center">
          <p className="text-4xl mb-2">🏆</p>
          <p className="text-sm text-muted font-medium">Las causas con más donaciones recibidas</p>
        </div>

        {sorted.length === 0 ? (
          <div className="card text-center py-10">
            <p className="text-4xl mb-3">❤️</p>
            <p className="text-muted font-medium text-sm">No hay causas disponibles aún.</p>
          </div>
        ) : (
          <div className="space-y-3">
            {sorted.map((cause, index) => {
              const rank = index + 1
              const medal = MEDALS[index] || null
              const pct = maxRaised > 0 ? Math.round(((cause.totalRaised || 0) / maxRaised) * 100) : 0

              return (
                <Link
                  key={cause.id}
                  href={`/c/${cause.slug}`}
                  className="card flex items-center gap-4 hover:shadow-md transition-all group block"
                  style={{
                    borderWidth: 2,
                    borderColor: rank <= 3 ? '#FF7A1A' : 'transparent',
                  }}
                >
                  {/* Rank */}
                  <div className="w-10 flex-shrink-0 text-center">
                    {medal ? (
                      <span className="text-2xl">{medal}</span>
                    ) : (
                      <span className="text-lg font-extrabold text-muted">#{rank}</span>
                    )}
                  </div>

                  {/* Logo */}
                  {cause.logo ? (
                    <img src={cause.logo} alt={cause.name} className="w-14 h-14 rounded-2xl object-cover flex-shrink-0" />
                  ) : (
                    <div className="w-14 h-14 rounded-2xl bg-primary-bg flex items-center justify-center flex-shrink-0 text-2xl">❤️</div>
                  )}

                  {/* Info */}
                  <div className="flex-1 min-w-0">
                    <p className="font-extrabold text-[#2D2D2D] text-sm">{cause.name}</p>
                    {cause.description && (
                      <p className="text-xs text-muted line-clamp-1 mt-0.5 leading-relaxed">{cause.description}</p>
                    )}
                    <div className="mt-2">
                      <div className="h-1.5 bg-border rounded-full overflow-hidden">
                        <div
                          className="h-full bg-primary rounded-full transition-all"
                          style={{ width: `${pct}%` }}
                        />
                      </div>
                    </div>
                    <p className="text-xs font-bold text-primary mt-1">
                      {formatCurrency(cause.totalRaised || 0)} recaudados
                    </p>
                  </div>

                  <span className="text-primary font-extrabold text-lg flex-shrink-0 group-hover:translate-x-0.5 transition-transform">→</span>
                </Link>
              )
            })}
          </div>
        )}

        <div className="mt-8 text-center">
          <Link href="/causas" className="text-primary font-bold text-sm hover:underline">
            ← Ver todas las causas
          </Link>
        </div>
      </main>
    </div>
  )
}
