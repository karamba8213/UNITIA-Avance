'use client'
import { LocaleProvider } from '@/context/LocaleContext'
import { CauseProvider } from '@/context/CauseContext'
import CauseSelectorModal from '@/components/CauseSelectorModal'
import GlobalBottomNav from '@/components/GlobalBottomNav'

export default function Providers({ children }) {
  return (
    <LocaleProvider>
      <CauseProvider>
        {children}
        <CauseSelectorModal />
        <GlobalBottomNav />
      </CauseProvider>
    </LocaleProvider>
  )
}
