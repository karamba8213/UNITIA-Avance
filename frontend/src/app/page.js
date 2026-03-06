import Link from 'next/link'

async function getFeaturedCauses() {
  try {
    const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/public/causes`, { next: { revalidate: 300 } })
    const data = await res.json()
    return data.success ? data.data : []
  } catch {
    return []
  }
}

export default async function LandingPage() {
  const causes = await getFeaturedCauses()

  return (
    <div className="min-h-screen">
      {/* Nav */}
      <nav className="bg-white border-b border-gray-100 sticky top-0 z-50">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 flex items-center justify-between h-16">
          <span className="text-xl font-bold text-primary">Unitia</span>
          <div className="flex items-center gap-4">
            <Link href="/login" className="text-gray-600 hover:text-primary font-medium text-sm">
              Iniciar sesión
            </Link>
            <Link href="/register" className="btn-primary text-sm px-4 py-2 rounded-lg">
              Unirse
            </Link>
          </div>
        </div>
      </nav>

      {/* Hero */}
      <section className="bg-gradient-to-br from-primary-50 to-secondary/20 py-24 px-4">
        <div className="max-w-4xl mx-auto text-center">
          <h1 className="text-4xl sm:text-5xl font-bold text-gray-900 leading-tight mb-6">
            Cada pedido <span className="text-primary">suma</span> a una causa real
          </h1>
          <p className="text-lg text-gray-600 mb-8 max-w-2xl mx-auto">
            Unitia conecta restaurantes con organizaciones sociales. Cada orden que tomás genera
            una donación automática a la causa que elegís apoyar.
          </p>
          <div className="flex flex-col sm:flex-row gap-3 justify-center">
            <Link href="/register?role=RESTAURANT" className="btn-primary text-base px-6 py-3 rounded-xl">
              Soy restaurante
            </Link>
            <Link href="/register?role=CAUSE" className="btn-secondary text-base px-6 py-3 rounded-xl">
              Tengo una causa
            </Link>
          </div>
        </div>
      </section>

      {/* How it works */}
      <section className="py-20 px-4 bg-white">
        <div className="max-w-5xl mx-auto">
          <h2 className="text-3xl font-bold text-center text-gray-900 mb-14">¿Cómo funciona?</h2>
          <div className="grid sm:grid-cols-3 gap-8">
            {[
              { step: '01', title: 'El restaurante elige una causa', desc: 'Se registra, configura su menú y selecciona qué porcentaje de cada pedido va a una causa social.' },
              { step: '02', title: 'Los clientes piden normalmente', desc: 'Escanean un QR o entran al link del restaurante. El pedido genera una donación automática, sin fricción.' },
              { step: '03', title: 'La causa recibe el apoyo', desc: 'El restaurante ve cuánto debe, lo transfiere, y la causa confirma. Todo trazable y transparente.' },
            ].map(({ step, title, desc }) => (
              <div key={step} className="text-center">
                <div className="w-12 h-12 rounded-full bg-primary text-white font-bold text-lg flex items-center justify-center mx-auto mb-4">
                  {step}
                </div>
                <h3 className="font-semibold text-gray-900 mb-2">{title}</h3>
                <p className="text-gray-500 text-sm leading-relaxed">{desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Featured Causes */}
      {causes.length > 0 && (
        <section className="py-20 px-4 bg-gray-50">
          <div className="max-w-5xl mx-auto">
            <h2 className="text-3xl font-bold text-center text-gray-900 mb-4">Causas activas</h2>
            <p className="text-center text-gray-500 mb-12">Organizaciones que ya están recibiendo el apoyo de restaurantes.</p>
            <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
              {causes.map(cause => (
                <Link
                  key={cause.id}
                  href={`/c/${cause.slug}`}
                  className="card hover:shadow-md transition-shadow group"
                >
                  {cause.logo && (
                    <img src={cause.logo} alt={cause.name} className="w-12 h-12 rounded-full object-cover mb-3" />
                  )}
                  <h3 className="font-semibold text-gray-900 group-hover:text-primary transition-colors">
                    {cause.name}
                  </h3>
                  <p className="text-sm text-gray-500 mt-1 line-clamp-2">{cause.description}</p>
                  {cause.targetAmount > 0 && (
                    <div className="mt-3">
                      <div className="h-1.5 bg-gray-200 rounded-full">
                        <div
                          className="h-1.5 bg-primary rounded-full transition-all"
                          style={{ width: `${cause.progress || 0}%` }}
                        />
                      </div>
                      <p className="text-xs text-gray-500 mt-1">
                        ${cause.totalRaised?.toLocaleString()} recaudado
                        {cause.progress ? ` · ${cause.progress}%` : ''}
                      </p>
                    </div>
                  )}
                  {cause._count?.restaurants > 0 && (
                    <p className="text-xs text-primary font-medium mt-2">
                      {cause._count.restaurants} restaurante{cause._count.restaurants !== 1 ? 's' : ''} apoyando
                    </p>
                  )}
                </Link>
              ))}
            </div>
          </div>
        </section>
      )}

      {/* CTA */}
      <section className="py-20 px-4 bg-primary text-white text-center">
        <h2 className="text-3xl font-bold mb-4">¿Listo para sumarte?</h2>
        <p className="text-primary-200 mb-8 max-w-xl mx-auto">
          Unís tu restaurante a la red en 5 minutos. Sin costos de entrada. La solidaridad como hábito.
        </p>
        <Link href="/register?role=RESTAURANT" className="inline-flex items-center px-8 py-4 bg-white text-primary font-semibold rounded-xl hover:bg-primary-50 transition-colors">
          Registrar mi restaurante
        </Link>
      </section>

      {/* Footer */}
      <footer className="bg-gray-900 text-gray-400 py-8 px-4 text-center text-sm">
        <p>© 2025 Unitia. Conectando restaurantes con causas que importan.</p>
      </footer>
    </div>
  )
}
