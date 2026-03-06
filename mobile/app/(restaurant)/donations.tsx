import { useEffect, useState } from 'react'
import { View, Text, StyleSheet, FlatList, TouchableOpacity, Alert, Modal, TextInput, RefreshControl } from 'react-native'
import { useSafeAreaInsets } from 'react-native-safe-area-context'
import { useRouter } from 'expo-router'
import { api } from '../../lib/api'
import { useAuth } from '../../lib/context'
import { formatCurrency, formatDate } from '../../lib/auth'
import Header from '../../components/layout/Header'
import Badge from '../../components/ui/Badge'
import Button from '../../components/ui/Button'

const FILTERS = [
  { v: '', l: 'Todas' },
  { v: 'PENDING', l: 'Pendientes' },
  { v: 'PAID', l: 'Pagadas' },
  { v: 'CONFIRMED', l: 'Confirmadas' },
]

export default function RestaurantDonations() {
  const insets = useSafeAreaInsets()
  const router = useRouter()
  const { logout } = useAuth()
  const [donations, setDonations] = useState<any[]>([])
  const [filter, setFilter] = useState('PENDING')
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [modalDonation, setModalDonation] = useState<any>(null)
  const [note, setNote] = useState('')
  const [paying, setPaying] = useState(false)

  useEffect(() => { load() }, [filter])

  async function load() {
    setLoading(true)
    try {
      const res = await api.donations.list({ status: filter, limit: 50 })
      setDonations(res.data.donations || [])
    } catch (err: any) {
      if (err.status === 401) { await logout(); router.replace('/(auth)/login') }
    } finally {
      setLoading(false)
      setRefreshing(false)
    }
  }

  async function markPaid() {
    if (!modalDonation) return
    setPaying(true)
    try {
      await api.donations.markPaid(modalDonation.id, note)
      setModalDonation(null)
      setNote('')
      load()
    } catch (err: any) {
      Alert.alert('Error', err.message)
    } finally {
      setPaying(false)
    }
  }

  return (
    <View style={{ flex: 1, backgroundColor: '#F9FAFB' }}>
      <Header title="Donaciones" showBack />

      {/* Filters */}
      <View style={styles.filterRow}>
        {FILTERS.map(f => (
          <TouchableOpacity
            key={f.v}
            onPress={() => setFilter(f.v)}
            style={[styles.filterBtn, filter === f.v && styles.filterBtnActive]}
          >
            <Text style={[styles.filterText, filter === f.v && styles.filterTextActive]}>{f.l}</Text>
          </TouchableOpacity>
        ))}
      </View>

      <FlatList
        data={donations}
        keyExtractor={d => d.id}
        contentContainerStyle={{ padding: 16, paddingBottom: insets.bottom + 24 }}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => { setRefreshing(true); load() }} tintColor="#2D6A4F" />}
        ListEmptyComponent={
          !loading ? (
            <View style={{ alignItems: 'center', paddingTop: 60 }}>
              <Text style={{ fontSize: 40, marginBottom: 12 }}>✅</Text>
              <Text style={{ color: '#6B7280', fontSize: 15 }}>No hay donaciones en este estado.</Text>
            </View>
          ) : null
        }
        renderItem={({ item }) => (
          <View style={styles.card}>
            <View style={{ flex: 1 }}>
              <Text style={styles.causeName}>{item.cause?.name}</Text>
              <Text style={styles.orderInfo}>
                {item.order?.customerName} · {item.order?.createdAt ? formatDate(item.order.createdAt) : ''}
              </Text>
              {item.notes && <Text style={styles.noteText}>"{item.notes}"</Text>}
            </View>
            <View style={{ alignItems: 'flex-end', gap: 6 }}>
              <Text style={styles.amount}>{formatCurrency(item.amount)}</Text>
              <Badge status={item.status} />
              {item.status === 'PENDING' && (
                <TouchableOpacity
                  style={styles.payBtn}
                  onPress={() => { setModalDonation(item); setNote('') }}
                >
                  <Text style={styles.payBtnText}>Marcar pagada</Text>
                </TouchableOpacity>
              )}
            </View>
          </View>
        )}
      />

      {/* Pay modal */}
      <Modal visible={!!modalDonation} transparent animationType="slide">
        <View style={styles.modalOverlay}>
          <View style={[styles.modalBox, { paddingBottom: insets.bottom + 16 }]}>
            <Text style={styles.modalTitle}>Confirmar pago</Text>
            <Text style={styles.modalSub}>
              Vas a marcar {formatCurrency(modalDonation?.amount || 0)} como pagado a {modalDonation?.cause?.name}.
            </Text>
            <Text style={{ fontSize: 13, color: '#374151', fontWeight: '500', marginBottom: 6 }}>Nota (opcional)</Text>
            <TextInput
              style={styles.noteInput}
              placeholder="Ej: transferencia #12345"
              value={note}
              onChangeText={setNote}
              placeholderTextColor="#9CA3AF"
            />
            <View style={{ flexDirection: 'row', gap: 10, marginTop: 8 }}>
              <Button label="Cancelar" variant="secondary" onPress={() => setModalDonation(null)} style={{ flex: 1 }} />
              <Button label="Confirmar" onPress={markPaid} loading={paying} style={{ flex: 1 }} />
            </View>
          </View>
        </View>
      </Modal>
    </View>
  )
}

const styles = StyleSheet.create({
  filterRow: {
    flexDirection: 'row', padding: 12, gap: 6, backgroundColor: '#fff',
    borderBottomWidth: 1, borderBottomColor: '#F3F4F6',
  },
  filterBtn: {
    paddingHorizontal: 12, paddingVertical: 6, borderRadius: 20,
    backgroundColor: '#F3F4F6',
  },
  filterBtnActive: { backgroundColor: '#2D6A4F' },
  filterText: { fontSize: 12, fontWeight: '600', color: '#6B7280' },
  filterTextActive: { color: '#fff' },
  card: {
    backgroundColor: '#fff', borderRadius: 14, padding: 14, marginBottom: 8,
    flexDirection: 'row', gap: 12,
    shadowColor: '#000', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.05, shadowRadius: 3, elevation: 2,
  },
  causeName: { fontSize: 14, fontWeight: '700', color: '#111827', marginBottom: 3 },
  orderInfo: { fontSize: 12, color: '#9CA3AF' },
  noteText: { fontSize: 11, color: '#6B7280', fontStyle: 'italic', marginTop: 2 },
  amount: { fontSize: 17, fontWeight: '800', color: '#111827' },
  payBtn: {
    backgroundColor: '#2D6A4F', paddingHorizontal: 10, paddingVertical: 5, borderRadius: 8,
  },
  payBtnText: { color: '#fff', fontSize: 11, fontWeight: '700' },
  modalOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.4)', justifyContent: 'flex-end' },
  modalBox: { backgroundColor: '#fff', borderTopLeftRadius: 24, borderTopRightRadius: 24, padding: 24 },
  modalTitle: { fontSize: 18, fontWeight: '800', color: '#111827', marginBottom: 6 },
  modalSub: { fontSize: 13, color: '#6B7280', marginBottom: 16 },
  noteInput: {
    borderWidth: 1, borderColor: '#D1D5DB', borderRadius: 10, paddingHorizontal: 12,
    height: 44, fontSize: 14, color: '#111827', backgroundColor: '#F9FAFB',
  },
})
