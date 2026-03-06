import { useEffect, useState } from 'react'
import { View, Text, StyleSheet, FlatList, TouchableOpacity, RefreshControl } from 'react-native'
import { useSafeAreaInsets } from 'react-native-safe-area-context'
import { useRouter } from 'expo-router'
import { api } from '../../lib/api'
import { useAuth } from '../../lib/context'
import { formatCurrency, formatDate } from '../../lib/auth'
import Header from '../../components/layout/Header'
import Badge from '../../components/ui/Badge'

export default function OrdersScreen() {
  const insets = useSafeAreaInsets()
  const router = useRouter()
  const { logout } = useAuth()
  const [orders, setOrders] = useState<any[]>([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(1)
  const [pages, setPages] = useState(1)
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [expanded, setExpanded] = useState<string | null>(null)

  useEffect(() => { load(1) }, [])

  async function load(p: number) {
    try {
      const res = await api.orders.list({ page: p, limit: 20 })
      if (p === 1) setOrders(res.data.orders || [])
      else setOrders(prev => [...prev, ...(res.data.orders || [])])
      setTotal(res.data.total)
      setPages(res.data.pages)
      setPage(p)
    } catch (err: any) {
      if (err.status === 401) { await logout(); router.replace('/(auth)/login') }
    } finally {
      setLoading(false)
      setRefreshing(false)
    }
  }

  return (
    <View style={{ flex: 1, backgroundColor: '#F9FAFB' }}>
      <Header title={`Pedidos (${total})`} showBack />

      <FlatList
        data={orders}
        keyExtractor={o => o.id}
        contentContainerStyle={{ padding: 16, paddingBottom: insets.bottom + 24 }}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => { setRefreshing(true); load(1) }} tintColor="#2D6A4F" />}
        onEndReached={() => { if (page < pages) load(page + 1) }}
        onEndReachedThreshold={0.3}
        ListEmptyComponent={
          !loading ? (
            <View style={{ alignItems: 'center', paddingTop: 60 }}>
              <Text style={{ fontSize: 40, marginBottom: 12 }}>📦</Text>
              <Text style={{ color: '#6B7280' }}>Aún no hay pedidos.</Text>
            </View>
          ) : null
        }
        renderItem={({ item }) => (
          <TouchableOpacity
            style={styles.card}
            onPress={() => setExpanded(expanded === item.id ? null : item.id)}
            activeOpacity={0.9}
          >
            <View style={styles.cardRow}>
              <View style={{ flex: 1 }}>
                <Text style={styles.customerName}>{item.customerName}</Text>
                <Text style={styles.dateText}>{formatDate(item.createdAt)}</Text>
              </View>
              <View style={{ alignItems: 'flex-end', gap: 4 }}>
                <Text style={styles.amount}>{formatCurrency(item.subtotal)}</Text>
                <Text style={{ color: '#2D6A4F', fontSize: 11 }}>+{formatCurrency(item.donationAmount)}</Text>
                {item.donation && <Badge status={item.donation.status} />}
              </View>
            </View>

            {expanded === item.id && (
              <View style={styles.expandedArea}>
                <View style={styles.divider} />
                {item.items?.map((line: any) => (
                  <View key={line.id} style={styles.lineRow}>
                    <Text style={styles.lineName}>{line.name} × {line.quantity}</Text>
                    <Text style={styles.linePrice}>{formatCurrency(line.price * line.quantity)}</Text>
                  </View>
                ))}
                {item.cause && (
                  <Text style={styles.causeNote}>Donación → {item.cause.name}</Text>
                )}
                {item.notes && <Text style={styles.noteText}>Nota: "{item.notes}"</Text>}
              </View>
            )}
          </TouchableOpacity>
        )}
      />
    </View>
  )
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#fff', borderRadius: 14, marginBottom: 8, overflow: 'hidden',
    shadowColor: '#000', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.05, shadowRadius: 3, elevation: 2,
  },
  cardRow: { flexDirection: 'row', padding: 14, gap: 12 },
  customerName: { fontSize: 14, fontWeight: '700', color: '#111827', marginBottom: 2 },
  dateText: { fontSize: 12, color: '#9CA3AF' },
  amount: { fontSize: 16, fontWeight: '800', color: '#111827' },
  expandedArea: { paddingHorizontal: 14, paddingBottom: 12 },
  divider: { height: 1, backgroundColor: '#F3F4F6', marginBottom: 10 },
  lineRow: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 4 },
  lineName: { fontSize: 13, color: '#374151' },
  linePrice: { fontSize: 13, fontWeight: '600', color: '#374151' },
  causeNote: { fontSize: 12, color: '#2D6A4F', fontWeight: '600', marginTop: 8 },
  noteText: { fontSize: 12, color: '#9CA3AF', fontStyle: 'italic', marginTop: 4 },
})
