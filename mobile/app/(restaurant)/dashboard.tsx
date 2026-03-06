import { useEffect, useState } from 'react'
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, RefreshControl, Alert } from 'react-native'
import { useSafeAreaInsets } from 'react-native-safe-area-context'
import { useRouter } from 'expo-router'
import { api } from '../../lib/api'
import { useAuth } from '../../lib/context'
import { formatCurrency, formatDate } from '../../lib/auth'
import Card from '../../components/ui/Card'

function StatCard({ label, value, sub, color = '#2D6A4F' }: any) {
  return (
    <View style={[statStyles.card, { flex: 1 }]}>
      <Text style={[statStyles.value, { color }]}>{value}</Text>
      <Text style={statStyles.label}>{label}</Text>
      {sub && <Text style={statStyles.sub}>{sub}</Text>}
    </View>
  )
}

const statStyles = StyleSheet.create({
  card: {
    backgroundColor: '#fff', borderRadius: 14, padding: 14, margin: 4,
    shadowColor: '#000', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.05, shadowRadius: 4, elevation: 2,
  },
  value: { fontSize: 20, fontWeight: '800', marginBottom: 2 },
  label: { fontSize: 11, color: '#6B7280', fontWeight: '500' },
  sub: { fontSize: 10, color: '#9CA3AF', marginTop: 2 },
})

export default function RestaurantDashboard() {
  const insets = useSafeAreaInsets()
  const router = useRouter()
  const { user, logout } = useAuth()
  const [dashboard, setDashboard] = useState<any>(null)
  const [profile, setProfile] = useState<any>(null)
  const [recentOrders, setRecentOrders] = useState<any[]>([])
  const [refreshing, setRefreshing] = useState(false)

  useEffect(() => { load() }, [])

  async function load() {
    try {
      const [d, p, o] = await Promise.all([
        api.restaurant.getDashboard(),
        api.restaurant.getProfile(),
        api.orders.list({ limit: 5 }),
      ])
      setDashboard(d.data)
      setProfile(p.data)
      setRecentOrders(o.data.orders || [])
    } catch (err: any) {
      if (err.status === 401) { await logout(); router.replace('/(auth)/login') }
    }
  }

  async function onRefresh() {
    setRefreshing(true)
    await load()
    setRefreshing(false)
  }

  async function handleLogout() {
    Alert.alert('Cerrar sesión', '¿Seguro?', [
      { text: 'Cancelar', style: 'cancel' },
      { text: 'Salir', style: 'destructive', onPress: async () => { await logout(); router.replace('/(auth)/login') } },
    ])
  }

  return (
    <View style={{ flex: 1, backgroundColor: '#F9FAFB' }}>
      {/* Header */}
      <View style={[styles.header, { paddingTop: insets.top + 12 }]}>
        <View>
          <Text style={styles.headerLogo}>Unitia</Text>
          <Text style={styles.headerSub}>Restaurante</Text>
        </View>
        <TouchableOpacity onPress={handleLogout}>
          <Text style={{ color: '#9CA3AF', fontSize: 13 }}>Salir</Text>
        </TouchableOpacity>
      </View>

      <ScrollView
        contentContainerStyle={{ padding: 16, paddingBottom: insets.bottom + 24 }}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor="#2D6A4F" />}
      >
        {/* Restaurant name & cause */}
        <View style={{ marginBottom: 16 }}>
          <Text style={styles.restaurantName}>{profile?.name || 'Mi Restaurante'}</Text>
          {profile?.cause
            ? <Text style={styles.causeTag}>Apoyando a {profile.cause.name} · {profile.donationPercentage}%</Text>
            : <TouchableOpacity onPress={() => router.push('/(restaurant)/settings')}>
                <Text style={[styles.causeTag, { color: '#F4A261' }]}>+ Elegir una causa →</Text>
              </TouchableOpacity>
          }
        </View>

        {/* Stats */}
        {dashboard && (
          <>
            <View style={styles.row}>
              <StatCard label="Pedidos hoy" value={dashboard.todayOrders} />
              <StatCard label="Ventas hoy" value={formatCurrency(dashboard.todayRevenue)} color="#059669" />
            </View>
            <View style={styles.row}>
              <StatCard label="Donaciones hoy" value={formatCurrency(dashboard.todayDonations)} color="#F4A261" />
              <StatCard
                label="Pendiente de pagar"
                value={formatCurrency(dashboard.donations.pending?.total || 0)}
                sub={`${dashboard.donations.pending?.count || 0} pedidos`}
                color="#D97706"
              />
            </View>
          </>
        )}

        {/* Quick actions */}
        <View style={styles.actionsRow}>
          {[
            { icon: '📋', label: 'Pedidos', route: '/(restaurant)/orders' },
            { icon: '💰', label: 'Donaciones', route: '/(restaurant)/donations' },
            { icon: '🍽', label: 'Menú', route: '/(restaurant)/menu' },
            { icon: '⚙️', label: 'Ajustes', route: '/(restaurant)/settings' },
          ].map(({ icon, label, route }) => (
            <TouchableOpacity key={route} style={styles.actionBtn} onPress={() => router.push(route as any)}>
              <Text style={styles.actionIcon}>{icon}</Text>
              <Text style={styles.actionLabel}>{label}</Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* Recent orders */}
        <Text style={styles.sectionTitle}>Pedidos recientes</Text>
        {recentOrders.length === 0 ? (
          <Card>
            <Text style={{ color: '#9CA3AF', textAlign: 'center', paddingVertical: 12 }}>
              Aún no hay pedidos.{profile?.slug ? `\nCompartí /r/${profile.slug}` : ''}
            </Text>
          </Card>
        ) : (
          recentOrders.map(order => (
            <Card key={order.id} style={{ marginBottom: 8 }}>
              <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <View style={{ flex: 1 }}>
                  <Text style={{ fontWeight: '600', color: '#111827', fontSize: 14 }}>{order.customerName}</Text>
                  <Text style={{ color: '#9CA3AF', fontSize: 12, marginTop: 2 }}>{formatDate(order.createdAt)}</Text>
                </View>
                <View style={{ alignItems: 'flex-end' }}>
                  <Text style={{ fontWeight: '700', color: '#111827', fontSize: 15 }}>{formatCurrency(order.subtotal)}</Text>
                  <Text style={{ color: '#2D6A4F', fontSize: 12, marginTop: 2 }}>+{formatCurrency(order.donationAmount)}</Text>
                </View>
              </View>
            </Card>
          ))
        )}
      </ScrollView>
    </View>
  )
}

const styles = StyleSheet.create({
  header: {
    backgroundColor: '#fff', borderBottomWidth: 1, borderBottomColor: '#F3F4F6',
    paddingHorizontal: 16, paddingBottom: 12,
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
  },
  headerLogo: { fontSize: 20, fontWeight: '800', color: '#2D6A4F' },
  headerSub: { fontSize: 11, color: '#9CA3AF', marginTop: -2 },
  restaurantName: { fontSize: 22, fontWeight: '800', color: '#111827' },
  causeTag: { fontSize: 13, color: '#2D6A4F', marginTop: 3, fontWeight: '500' },
  row: { flexDirection: 'row', marginBottom: 0 },
  actionsRow: {
    flexDirection: 'row', justifyContent: 'space-between',
    backgroundColor: '#fff', borderRadius: 16, padding: 8, marginVertical: 12,
    shadowColor: '#000', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.05, shadowRadius: 4, elevation: 2,
  },
  actionBtn: { flex: 1, alignItems: 'center', padding: 10 },
  actionIcon: { fontSize: 22, marginBottom: 4 },
  actionLabel: { fontSize: 11, color: '#374151', fontWeight: '500' },
  sectionTitle: { fontSize: 15, fontWeight: '700', color: '#111827', marginBottom: 8, marginTop: 4 },
})
