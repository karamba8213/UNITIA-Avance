'use client'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { useCause } from '@/context/CauseContext'
import { useLocale } from '@/context/LocaleContext'

function HomeIcon(active) {
  return <svg viewBox="0 0 24 24" fill={active ? 'currentColor' : 'none'} stroke="currentColor" strokeWidth={2} className="w-6 h-6"><path strokeLinecap="round" strokeLinejoin="round" d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" /><polyline points="9 22 9 12 15 12 15 22" /></svg>
}
function HeartIcon(active) {
  return <svg viewBox="0 0 24 24" fill={active ? 'currentColor' : 'none'} stroke="currentColor" strokeWidth={2} className="w-6 h-6"><path strokeLinecap="round" strokeLinejoin="round" d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" /></svg>
}
function ForkIcon() {
  return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-6 h-6"><path strokeLinecap="round" strokeLinejoin="round" d="M3 2v7c0 1.1.9 2 2 2h4a2 2 0 0 0 2-2V2" /><path strokeLinecap="round" strokeLinejoin="round" d="M7 2v20" /><path strokeLinecap="round" strokeLinejoin="round" d="M21 15V2a5 5 0 0 0-5 5v6c0 1.1.9 2 2 2h3zm0 0v7" /></svg>
}
function ChartIcon() {
  return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-6 h-6"><polyline strokeLinecap="round" strokeLinejoin="round" points="22 12 18 12 15 21 9 3 6 12 2 12" /></svg>
}
function PersonIcon(active) {
  return <svg viewBox="0 0 24 24" fill={active ? 'currentColor' : 'none'} stroke="currentColor" strokeWidth={2} className="w-6 h-6"><path strokeLinecap="round" strokeLinejoin="round" d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" /><circle cx="12" cy="7" r="4" /></svg>
}
function ClipboardIcon() {
  return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-6 h-6"><path strokeLinecap="round" strokeLinejoin="round" d="M9 5H7a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-2" /><rect x="9" y="3" width="6" height="4" rx="1" /></svg>
}
function MenuIcon() {
  return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-6 h-6"><path strokeLinecap="round" strokeLinejoin="round" d="M3 6h18M3 12h18M3 18h18" /></svg>
}
function SettingsIcon() {
  return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-6 h-6"><circle cx="12" cy="12" r="3" /><path strokeLinecap="round" strokeLinejoin="round" d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" /></svg>
}
function BellIcon() {
  return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-6 h-6"><path strokeLinecap="round" strokeLinejoin="round" d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" /><path strokeLinecap="round" strokeLinejoin="round" d="M13.73 21a2 2 0 0 1-3.46 0" /></svg>
}

export default function BottomNav({ role }) {
  const pathname = usePathname()
  const { t } = useLocale()
  const { selectedCause, openSelector } = useCause()

  const restaurantItems = [
    { href: '/restaurant/dashboard', label: t('nav.home'), icon: HomeIcon },
    { href: '/restaurant/orders', label: t('nav.orders'), icon: ClipboardIcon },
    { href: '/restaurant/donations', label: t('nav.donations'), icon: HeartIcon },
    { href: '/restaurant/menu', label: t('nav.menu'), icon: MenuIcon },
    { href: '/restaurant/settings', label: t('nav.settings'), icon: SettingsIcon },
  ]

  const customerItems = [
    { href: '/inicio', label: t('nav.home'), icon: HomeIcon },
    { href: '/causas', label: t('nav.causes'), icon: HeartIcon },
    { href: '/restaurantes', label: t('nav.order'), icon: ForkIcon },
    { href: '/mi-impacto', label: t('nav.impact'), icon: ChartIcon },
    { href: '/cuenta', label: t('nav.account'), icon: PersonIcon },
  ]

  const causeItems = [
    { href: '/cause/dashboard', label: t('nav.home'), icon: HomeIcon },
    { href: '/cause/donations', label: t('nav.donations'), icon: HeartIcon },
    { href: '/cause/updates', label: t('nav.updates'), icon: BellIcon },
    { href: '/cause/settings', label: t('nav.profile'), icon: PersonIcon },
  ]

  const homeHrefs = ['/restaurant/dashboard', '/cause/dashboard', '/inicio']
  const items = role === 'restaurant' ? restaurantItems
    : role === 'customer' ? customerItems
    : causeItems

  return (
    <>
      {/* Selected cause bar — only for customers, hidden on cause detail pages */}
      {role === 'customer' && !pathname.startsWith('/c/') && (
        <div className="fixed bottom-[64px] left-0 right-0 z-40 px-4 pb-1">
          <button
            onClick={openSelector}
            className="w-full flex items-center gap-2 bg-white border border-border rounded-2xl px-4 py-2.5 shadow-sm hover:border-primary/40 transition-all active:scale-[0.99]"
            style={{ boxShadow: '0 2px 12px rgba(0,0,0,0.06)' }}
          >
            {selectedCause ? (
              <>
                {selectedCause.logo ? (
                  <img src={selectedCause.logo} alt="" className="w-6 h-6 rounded-lg object-cover flex-shrink-0" />
                ) : (
                  <span className="text-base flex-shrink-0">❤️</span>
                )}
                <span className="text-xs font-bold text-[#2D2D2D] flex-1 truncate text-left">
                  {selectedCause.name}
                </span>
                <span className="text-xs text-primary font-bold flex-shrink-0">{t('cause.change')}</span>
              </>
            ) : (
              <>
                <span className="text-base flex-shrink-0">❤️</span>
                <span className="text-xs font-bold text-primary flex-1 text-left">{t('cause.choose')}</span>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} className="w-4 h-4 text-primary flex-shrink-0">
                  <polyline points="9 18 15 12 9 6" />
                </svg>
              </>
            )}
          </button>
        </div>
      )}

      {/* Tab bar */}
      <nav
        className="fixed bottom-0 left-0 right-0 z-50 bg-white border-t border-border"
        style={{ boxShadow: '0 -2px 12px rgba(0,0,0,0.06)' }}
      >
        <div className="flex justify-around items-center px-2 pt-2 pb-4">
          {items.map(({ href, label, icon }) => {
            const active = pathname === href || (!homeHrefs.includes(href) && pathname.startsWith(href))
            return (
              <Link
                key={href}
                href={href}
                className={`flex flex-col items-center gap-1 px-3 py-1 rounded-xl transition-colors min-w-0 ${
                  active ? 'text-primary' : 'text-muted hover:text-primary'
                }`}
              >
                {icon(active)}
                <span className="text-[10px] font-bold tracking-wide leading-none uppercase">{label}</span>
              </Link>
            )
          })}
        </div>
      </nav>
    </>
  )
}
