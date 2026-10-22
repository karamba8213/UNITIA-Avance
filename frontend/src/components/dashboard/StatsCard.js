export default function StatsCard({ label, value, sub, color = 'primary', icon }) {
  const colorMap = {
    primary: { text: 'text-primary', bg: 'bg-primary/10' },
    green: { text: 'text-green-600', bg: 'bg-green-50' },
    blue: { text: 'text-blue-500', bg: 'bg-blue-50' },
    yellow: { text: 'text-amber-500', bg: 'bg-amber-50' },
    orange: { text: 'text-primary', bg: 'bg-primary/10' },
  }
  const { text, bg } = colorMap[color] || colorMap.primary

  return (
    <div className="card">
      {icon && (
        <div className={`w-9 h-9 rounded-full ${bg} flex items-center justify-center mb-3`}>
          <span className={`${text}`}>{icon}</span>
        </div>
      )}
      <p className={`text-2xl font-extrabold ${text}`}>{value}</p>
      <p className="text-xs font-semibold text-muted mt-1 uppercase tracking-wide leading-snug">{label}</p>
      {sub && <p className="text-xs text-muted mt-0.5">{sub}</p>}
    </div>
  )
}
