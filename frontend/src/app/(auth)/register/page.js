'use client'
import { useState, Suspense } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import Link from 'next/link'
import { api } from '@/lib/api'
import { saveTokens, saveUser } from '@/lib/auth'

function RegisterForm() {
  const router = useRouter()
  const params = useSearchParams()
  const defaultRole = params.get('role') || 'RESTAURANT'

  const [role, setRole] = useState(defaultRole)
  const [form, setForm] = useState({
    email: '', password: '', name: '',
    profile: { name: '', description: '', donationPercentage: 5, story: '', targetAmount: 0 }
  })
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  function setField(field, value) {
    setForm(f => ({ ...f, [field]: value }))
  }
  function setProfile(field, value) {
    setForm(f => ({ ...f, profile: { ...f.profile, [field]: value } }))
  }

  async function handleSubmit(e) {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      const { data } = await api.auth.register({ ...form, role })
      saveTokens(data.accessToken, data.refreshToken)
      saveUser(data.user)
      if (role === 'RESTAURANT') router.push('/restaurant/dashboard')
      else router.push('/cause/dashboard')
    } catch (err) {
      setError(err.message || 'Error al registrarse')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4 py-12">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <Link href="/" className="text-2xl font-bold text-primary">Unitia</Link>
          <p className="text-gray-500 mt-2 text-sm">Crear cuenta</p>
        </div>

        {/* Role selector */}
        <div className="flex rounded-lg border border-gray-200 bg-white p-1 mb-6">
          {['RESTAURANT', 'CAUSE'].map(r => (
            <button
              key={r}
              type="button"
              onClick={() => setRole(r)}
              className={`flex-1 py-2 px-3 rounded-md text-sm font-medium transition-colors ${
                role === r ? 'bg-primary text-white' : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              {r === 'RESTAURANT' ? 'Soy restaurante' : 'Tengo una causa'}
            </button>
          ))}
        </div>

        <div className="card">
          {error && (
            <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
              {error}
            </div>
          )}
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Tu nombre completo</label>
              <input className="input" value={form.name} onChange={e => setField('name', e.target.value)} required />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
              <input type="email" className="input" value={form.email} onChange={e => setField('email', e.target.value)} required />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Contraseña</label>
              <input type="password" className="input" value={form.password} onChange={e => setField('password', e.target.value)} required minLength={8} />
            </div>

            <hr className="border-gray-100" />

            {role === 'RESTAURANT' ? (
              <>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Nombre del restaurante</label>
                  <input className="input" value={form.profile.name} onChange={e => setProfile('name', e.target.value)} />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Descripción breve</label>
                  <textarea className="input resize-none" rows={2} value={form.profile.description} onChange={e => setProfile('description', e.target.value)} />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    % de donación por pedido <span className="text-gray-400">(recomendado: 5%)</span>
                  </label>
                  <input type="number" className="input" min={0} max={100} step={0.5} value={form.profile.donationPercentage} onChange={e => setProfile('donationPercentage', parseFloat(e.target.value))} />
                </div>
              </>
            ) : (
              <>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Nombre de la organización</label>
                  <input className="input" value={form.profile.name} onChange={e => setProfile('name', e.target.value)} />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Descripción breve</label>
                  <textarea className="input resize-none" rows={2} value={form.profile.description} onChange={e => setProfile('description', e.target.value)} />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Objetivo de recaudación (opcional)</label>
                  <input type="number" className="input" min={0} value={form.profile.targetAmount} onChange={e => setProfile('targetAmount', parseFloat(e.target.value))} />
                </div>
              </>
            )}

            <button type="submit" className="btn-primary w-full" disabled={loading}>
              {loading ? 'Creando cuenta...' : 'Crear cuenta'}
            </button>
          </form>
          <p className="text-center text-sm text-gray-500 mt-4">
            ¿Ya tenés cuenta?{' '}
            <Link href="/login" className="text-primary font-medium hover:underline">Iniciá sesión</Link>
          </p>
        </div>
      </div>
    </div>
  )
}

export default function RegisterPage() {
  return (
    <Suspense>
      <RegisterForm />
    </Suspense>
  )
}
