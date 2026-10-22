import Link from 'next/link'
import SelectCauseButton from './SelectCauseButton'

export async function generateMetadata({ params }) {
  try {
    const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/public/causes/${params.slug}`, { next: { revalidate: 60 } })
    const data = await res.json()
    if (!data.success) return { title: 'Causa no encontrada — Unitia' }
    return {
      title: `${data.data.name} — Unitia`,
      description: data.data.description,
      openGraph: {
        title: data.data.name,
        description: data.data.description,
        images: data.data.logo ? [{ url: data.data.logo }] : [],
      },
    }
  } catch {
    return { title: 'Unitia' }
  }
}

async function getCause(slug) {
  const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/public/causes/${slug}`, { next: { revalidate: 60 } })
  const data = await res.json()
  if (!data.success) return null
  return data.data
}

function formatMXN(n) {
  return new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(n || 0)
}

function ProgressBar({ progress, totalRaised, targetAmount }) {
  return (
    <div className="mb-5">
      <div className="flex justify-between items-baseline mb-2">
        <div>
          <span className="text-2xl font-extrabold text-primary">{formatMXN(totalRaised)}</span>
          <span className="text-sm text-muted font-medium ml-1.5">recaudados</span>
        </div>
        {targetAmount > 0 && (
          <span className="text-sm text-muted font-medium">meta {formatMXN(targetAmount)}</span>
        )}
      </div>
      {progress !== null ? (
        <>
          <div className="h-3 bg-border rounded-full overflow-hidden">
            <div
              className="h-3 bg-gradient-to-r from-primary to-primary-light rounded-full"
              style={{ width: `${Math.min(progress, 100)}%` }}
            />
          </div>
          <p className="text-xs text-muted mt-1.5 font-medium">{progress}% del objetivo alcanzado</p>
        </>
      ) : (
        <p className="text-xs text-muted font-medium">Sin meta fija · cada peso suma</p>
      )}
    </div>
  )
}

export default async function PublicCausePage({ params }) {
  const cause = await getCause(params.slug)

  if (!cause) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="text-center">
          <p className="text-5xl mb-4">❤️</p>
          <h1 className="text-2xl font-extrabold text-[#2D2D2D] mb-2">Causa no encontrada</h1>
          <Link href="/" className="text-primary font-bold hover:underline">Volver al inicio</Link>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-background pb-32">
      {/* Header */}
      <nav className="bg-white border-b border-border sticky top-0 z-40" style={{ boxShadow: '0 1px 8px rgba(0,0,0,0.06)' }}>
        <div className="max-w-2xl mx-auto px-4 flex items-center gap-3 h-14">
          <Link
            href="/causas"
            className="w-9 h-9 rounded-xl border border-border flex items-center justify-center text-muted hover:text-primary transition-colors flex-shrink-0"
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4">
              <path strokeLinecap="round" strokeLinejoin="round" d="M19 12H5m7-7-7 7 7 7" />
            </svg>
          </Link>
          <span className="font-extrabold text-[#2D2D2D] flex-1 truncate">{cause.name}</span>
        </div>
      </nav>

      <main className="max-w-2xl mx-auto px-4 py-6">
        {/* Hero */}
        <div className="card mb-4">
          {/* Logo grande */}
          <div className="flex justify-center mb-4">
            {cause.logo ? (
              <img src={cause.logo} alt={cause.name} className="w-24 h-24 rounded-3xl object-cover shadow-md" />
            ) : (
              <div className="w-24 h-24 rounded-3xl bg-primary-bg flex items-center justify-center text-5xl">❤️</div>
            )}
          </div>

          <h1 className="text-2xl font-extrabold text-[#2D2D2D] text-center mb-1">{cause.name}</h1>
          {cause.description && (
            <p className="text-muted text-sm leading-relaxed text-center mb-5">{cause.description}</p>
          )}

          <ProgressBar
            progress={cause.progress}
            totalRaised={cause.totalRaised}
            targetAmount={cause.targetAmount}
          />

          <div className="grid grid-cols-2 gap-3 text-center">
            <div className="bg-background rounded-2xl py-4">
              <p className="text-2xl font-extrabold text-primary">{cause.totalDonations || 0}</p>
              <p className="text-xs text-muted font-semibold mt-0.5">pedidos a tu favor</p>
            </div>
            <div className="bg-background rounded-2xl py-4">
              <p className="text-2xl font-extrabold text-primary">❤️</p>
              <p className="text-xs text-muted font-semibold mt-0.5">apoyada por Unitia</p>
            </div>
          </div>
        </div>

        {/* Story */}
        {cause.story && (
          <div className="card mb-4">
            <h2 className="font-extrabold text-[#2D2D2D] mb-3">Nuestra historia</h2>
            <div className="text-muted leading-relaxed whitespace-pre-wrap text-sm">
              {cause.story}
            </div>
          </div>
        )}

        {/* Images */}
        {cause.images?.length > 0 && (
          <div className="grid grid-cols-2 gap-3 mb-4">
            {cause.images.map((img, i) => (
              <img key={i} src={img} alt="" className="rounded-2xl object-cover w-full h-40" />
            ))}
          </div>
        )}


        {/* Select cause CTA — sticky al fondo */}
        <div className="fixed bottom-[72px] left-0 right-0 px-4 pb-2 z-30">
          <div className="max-w-2xl mx-auto">
            <SelectCauseButton causeSlug={cause.slug} causeId={cause.id} causeName={cause.name} causeLogo={cause.logo} />
          </div>
        </div>
      </main>
    </div>
  )
}
