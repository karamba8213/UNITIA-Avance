'use client'
import { createContext, useContext, useState, useEffect, useCallback } from 'react'
import { api } from '@/lib/api'
import { getUser } from '@/lib/auth'

const CauseContext = createContext(null)

export function CauseProvider({ children }) {
  const [selectedCause, setSelectedCause] = useState(null)
  const [allCauses, setAllCauses] = useState([])
  const [causesLoaded, setCausesLoaded] = useState(false)
  const [selectorOpen, setSelectorOpen] = useState(false)

  // Load causes + restore selection from localStorage
  useEffect(() => {
    api.public.getCauses()
      .then(res => {
        const causes = res.data || []
        setAllCauses(causes)
        setCausesLoaded(true)

        // Restore from localStorage
        try {
          const saved = localStorage.getItem('unitia_selected_cause')
          if (saved) {
            const parsed = JSON.parse(saved)
            // Verify cause still exists and is active
            const found = causes.find(c => c.id === parsed.id)
            if (found) setSelectedCause(found)
            else localStorage.removeItem('unitia_selected_cause')
          }
        } catch {
          localStorage.removeItem('unitia_selected_cause')
        }
      })
      .catch(() => setCausesLoaded(true))
  }, [])

  const selectCause = useCallback(async (cause) => {
    setSelectedCause(cause)
    setSelectorOpen(false)
    try {
      localStorage.setItem('unitia_selected_cause', JSON.stringify(cause))
    } catch {}
    // Sync to backend if logged in customer
    const user = getUser()
    if (user?.role === 'CUSTOMER') {
      try { await api.customer.selectCause(cause.id) } catch {}
    }
  }, [])

  const clearCause = useCallback(async () => {
    setSelectedCause(null)
    try { localStorage.removeItem('unitia_selected_cause') } catch {}
    const user = getUser()
    if (user?.role === 'CUSTOMER') {
      try { await api.customer.clearCause() } catch {}
    }
  }, [])

  return (
    <CauseContext.Provider value={{
      selectedCause,
      allCauses,
      causesLoaded,
      selectorOpen,
      selectCause,
      clearCause,
      openSelector: () => setSelectorOpen(true),
      closeSelector: () => setSelectorOpen(false),
    }}>
      {children}
    </CauseContext.Provider>
  )
}

export function useCause() {
  const ctx = useContext(CauseContext)
  if (!ctx) throw new Error('useCause must be used within CauseProvider')
  return ctx
}
