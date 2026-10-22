'use client'
import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { getUser } from '@/lib/auth'
import { useCause } from '@/context/CauseContext'

export default function SelectCauseButton({ causeSlug, causeId, causeName, causeLogo }) {
  const router = useRouter()
  const [loading, setLoading] = useState(false)
  const { selectCause } = useCause()
  const user = typeof window !== 'undefined' ? getUser() : null

  async function handleSelect() {
    setLoading(true)
    await selectCause({ id: causeId, slug: causeSlug, name: causeName, logo: causeLogo })
    router.push(`/restaurantes?cause=${causeSlug}`)
  }

  if (user?.role === 'CUSTOMER') {
    return (
      <button
        onClick={handleSelect}
        disabled={loading}
        className="btn btn-primary w-full text-base py-4"
      >
        {loading ? 'Guardando...' : '❤️ Elegir esta causa y pedir'}
      </button>
    )
  }

  return (
    <a
      href={`/login?callbackUrl=/c/${causeSlug}`}
      className="btn btn-primary w-full text-base py-4 flex items-center justify-center"
    >
      Inicia sesión para apoyar
    </a>
  )
}
