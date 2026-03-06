import React, { createContext, useContext, useEffect, useState } from 'react'
import { getStoredUser, clearSession } from './auth'

interface User {
  id: string
  email: string
  name: string
  role: 'RESTAURANT' | 'CAUSE' | 'ADMIN'
}

interface AuthContextType {
  user: User | null
  loading: boolean
  setUser: (u: User | null) => void
  logout: () => Promise<void>
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  loading: true,
  setUser: () => {},
  logout: async () => {},
})

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    getStoredUser().then(u => {
      setUser(u)
      setLoading(false)
    })
  }, [])

  async function logout() {
    await clearSession()
    setUser(null)
  }

  return (
    <AuthContext.Provider value={{ user, loading, setUser, logout }}>
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => useContext(AuthContext)
