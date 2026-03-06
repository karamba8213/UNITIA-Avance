import { View, Text, StyleSheet } from 'react-native'

const COLORS: Record<string, { bg: string; text: string }> = {
  PENDING:   { bg: '#FEF3C7', text: '#92400E' },
  PAID:      { bg: '#DBEAFE', text: '#1E40AF' },
  CONFIRMED: { bg: '#D1FAE5', text: '#065F46' },
  DISPUTED:  { bg: '#FEE2E2', text: '#991B1B' },
  CONFIRMED_ORDER: { bg: '#D1FAE5', text: '#065F46' },
}

const LABELS: Record<string, string> = {
  PENDING: 'Pendiente',
  PAID: 'Pagada',
  CONFIRMED: 'Confirmada',
  DISPUTED: 'En disputa',
}

export default function Badge({ status }: { status: string }) {
  const c = COLORS[status] || { bg: '#F3F4F6', text: '#6B7280' }
  return (
    <View style={[styles.badge, { backgroundColor: c.bg }]}>
      <Text style={[styles.text, { color: c.text }]}>{LABELS[status] || status}</Text>
    </View>
  )
}

const styles = StyleSheet.create({
  badge: { paddingHorizontal: 8, paddingVertical: 3, borderRadius: 20 },
  text: { fontSize: 11, fontWeight: '600' },
})
