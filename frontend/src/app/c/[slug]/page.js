import Link from 'next/link'

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

function ProgressBar({ progress, totalRaised, targetAmount }) {
  return (
    <div className="mb-6">
      <div className="flex justify-between text-sm mb-2 font-medium">
        <span className="text-gray-900 text-xl font-bold">${totalRaised?.toLocaleString('es-AR')}</span>
        {targetAmount > 0 && (
          <span className="text-gray-500">de ${targetAmount.toLocaleString('es-AR')}</span>
        )}
      </div>
      {progress !== null && (
        <div className="h-3 bg-gray-200 rounded-full overflow-hidden">
          <div
            className="h-3 bg-gradient-to-r from-primary to-secondary rounded-full"
            style={{ width: `${progress}%` }}
          />
        </div>
      )}
      {progress !== null && (
        <p className="text-sm text-gray-500 mt-1">{progress}% del objetivo alcanzado</p>
      )}
    </div>
  )
}

export default async function PublicCausePage({ params }) {
  const cause = await getCause(params.slug)

  if (!cause) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-gray-900 mb-2">Causa no encontrada</h1>
          <Link href="/" className="text-primary hover:underline">Volver al inicio</Link>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white border-b border-gray-100">
        <div className="max-w-5xl mx-auto px-4 sm:px-6 flex items-center justify-between h-14">
          <Link href="/" className="text-lg font-bold text-primary">Unitia</Link>
          <Link href="/register?role=RESTAURANT" className="btn-primary text-sm">
            Sumar mi restaurante
          </Link>
        </div>
      </nav>

      <main className="max-w-3xl mx-auto px-4 sm:px-6 py-10">
        {/* Hero */}
        <div className="card mb-6">
          <div className="flex items-start gap-4 mb-6">
            {cause.logo && (
              <img src={cause.logo} alt={cause.name} className="w-16 h-16 rounded-full object-cover flex-shrink-0" />
            )}
            <div>
              <h1 className="text-2xl font-bold text-gray-900">{cause.name}</h1>
              <p className="text-gray-500 mt-1">{cause.description}</p>
            </div>
          </div>

          <ProgressBar
            progress={cause.progress}
            totalRaised={cause.totalRaised}
            targetAmount={cause.targetAmount}
          />

          <div className="grid grid-cols-2 gap-4 text-center">
            <div className="bg-gray-50 rounded-lg py-3">
              <p className="text-2xl font-bold text-primary">{cause.totalDonations}</p>
              <p className="text-xs text-gray-500">donaciones recibidas</p>
            </div>
            <div className="bg-gray-50 rounded-lg py-3">
              <p className="text-2xl font-bold text-primary">{cause.restaurants?.length}</p>
              <p className="text-xs text-gray-500">restaurantes apoyando</p>
            </div>
          </div>
        </div>

        {/* Story */}
        {cause.story && (
          <div className="card mb-6">
            <h2 className="font-semibold text-gray-900 mb-3">Nuestra historia</h2>
            <div className="text-gray-600 leading-relaxed whitespace-pre-wrap text-sm">
              {cause.story}
            </div>
          </div>
        )}

        {/* Images */}
        {cause.images?.length > 0 && (
          <div className="grid grid-cols-2 gap-3 mb-6">
            {cause.images.map((img, i) => (
              <img key={i} src={img} alt="" className="rounded-xl object-cover w-full h-40" />
            ))}
          </div>
        )}

        {/* Restaurants */}
        {cause.restaurants?.length > 0 && (
          <div className="card mb-6">
            <h2 className="font-semibold text-gray-900 mb-3">Restaurantes que nos apoyan</h2>
            <div className="space-y-3">
              {cause.restaurants.map(r => (
                <Link
                  key={r.id}
                  href={`/r/${r.slug}`}
                  className="flex items-center gap-3 p-3 rounded-lg hover:bg-gray-50 transition-colors"
                >
                  {r.logo ? (
                    <img src={r.logo} alt={r.name} className="w-8 h-8 rounded-full object-cover" />
                  ) : (
                    <div className="w-8 h-8 rounded-full bg-primary-100 flex items-center justify-center text-primary font-bold text-sm">
                      {r.name[0]}
                    </div>
                  )}
                  <span className="font-medium text-gray-900 text-sm">{r.name}</span>
                  <span className="ml-auto text-xs text-primary">Pedir aquí →</span>
                </Link>
              ))}
            </div>
          </div>
        )}

        {/* Share CTA */}
        <div className="bg-primary rounded-xl p-6 text-white text-center">
          <h3 className="font-bold text-lg mb-2">¿Tenés un restaurante?</h3>
          <p className="text-primary-200 text-sm mb-4">Sumate y que cada pedido apoye a {cause.name}</p>
          <Link href="/register?role=RESTAURANT" className="inline-flex items-center px-6 py-2.5 bg-white text-primary font-semibold rounded-lg hover:bg-primary-50 transition-colors text-sm">
            Unirme como restaurante
          </Link>
        </div>
      </main>
    </div>
  )
}
