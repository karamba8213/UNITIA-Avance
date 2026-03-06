import { useEffect, useState } from 'react'
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, RefreshControl, Alert } from 'react-native'
import { useSafeAreaInsets } from 'react-native-safe-area-context'
import { useRouter } from 'expo-router'
import { api } from '../../lib/api'
import { useAuth } from '../../lib/context'
import { formatCurrency, formatDate } from '../../lib/auth'
import Card from '../../components/ui/Card'
import Badge from '../../components/ui/Badge'
import Button from '../../components/ui/Button'

function ProgressBar({ progress }: { progress: number }) {
  return (
    <View style={styles.progressContainer}>
      <View style={[styles.progressFill, { width: `${Math.min(progress, 100)}%` as any }]} />
    </View>
  )
}

export default function CauseDashboard() {
  const insets = useSafeAreaInsets()
  const router = useRouter()
  const { user, logout } = useAuth()
  const [dashboard, setDashboard] = useState<any>(null)
  const [profile, setProfile] = useState<any>(null)
  const [paidDonations, setPaidDonations] = useState<any[]>([])
  const [refreshing, setRefreshing] = useState(false)
  const [confirming, setConfirming] = useState<string | null>(null)

  useEffect(() => { load() }, [])

  async function load() {
    try {
      const [d, p, don] = await Promise.all([
        api.cause.getDashboard(),
        api.cause.getProfile(),
        api.donations.list({ status: 'PAID', limit: 20 }),
      ])
      setDashboard(d.data)
      setProfile(p.data)
      setPaidDonations(don.data.donations || [])
    } catch (err: any) {
      if (err.status === 401) { await logout(); router.replace('/(auth)/login') }
    } finally {
      setRefreshing(false)
    }
  }

  async function confirm(id: string) {
    setConfirming(id)
    try {
      await api.donations.confirm(id)
      setPaidDonations(d => d.filter(x => x.id !== id))
      load()
    } catch (err: any) {
      Alert.alert('Error', err.message)
    } finally {
      setConfirming(null)
    }
  }

  async function handleLogout() {
    Alert.alert('Cerrar sesión', '¿Seguro?', [
      { text: 'Cancelar', style: 'cancel' },
      { text: 'Salir', style: 'destructive', onPress: async () => { await logout(); router.replace('/(auth)/login') } },
    ])
  }

  return (
    <View style={{ flex: 1, backgroundColor: '#F9FAFB' }}>
      <View style={[styles.header, { paddingTop: insets.top + 12 }]}>
        <View>
          <Text style={styles.logo}>Unitia</Text>
          <Text style={styles.headerSub}>Causa social</Text>
        </View>
        <TouchableOpacity onPress={handleLogout}>
          <Text style={{ color: '#9CA3AF', fontSize: 13 }}>Salir</Text>
        </TouchableOpacity>
      </View>

      <ScrollView
        contentContainerStyle={{ padding: 16, paddingBottom: insets.bottom + 24 }}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => { setRefreshing(true); load() }} tintColor="#2D6A4F" />}
      >
        <View style={{ marginBottom: 16 }}>
          <Text style={styles.causeName}>{profile?.name}</Text>
          <Text style={styles.causeRestaurants}>
            {dashboard?.restaurantCount || 0} restaurante{dashboard?.restaurantCount !== 1 ? 's' : ''} apoyándote
          </Text>
        </View>

        {/* Stats */}
        {dashboard && (
          <>
            <View style={styles.statsRow}>
              <View style={[styles.statCard, { flex: 1 }]}>
                <Text style={[styles.statValue, { color: '#059669' }]}>{formatCurrency(dashboard.totalRaised)}</Text>
                <Text style={styles.statLabel}>Total recaudado</Text>
              </View>
              <View style={[styles.statCard, { flex: 1 }]}>
                <Text style={[styles.statValue, { color: '#1D4ED8' }]}>{formatCurrency(dashboard.donations.paid?.total || 0)}</Text>
                <Text style={styles.statLabel}>Para confirmar</Text>
              </View>
            </View>
            <View style={styles.statsRow}>
              <View style={[styles.statCard, { flex: 1 }]}>
                <Text style={[styles.statValue, { color: '#D97706' }]}>{formatCurrency(dashboard.donations.pending?.total || 0)}</Text>
                <Text style={styles.statLabel}>Por recibir</Text>
              </View>
              <View style={[styles.statCard, { flex: 1 }]}>
                <Text style={[styles.statValue, { color: '#2D6A4F' }]}>{dashboard.restaurantCount}</Text>
                <Text style={styles.statLabel}>Restaurantes</Text>
              </View>
            </View>
          </>
        )}

        {/* Progress */}
        {dashboard?.progress !== null && profile?.targetAmount > 0 && (
          <Card>
            <View style={{ flexDirection: 'row', justifyContent: 'space-between', marginBottom: 8 }}>
              <Text style={{ fontSize: 13, fontWeight: '600', color: '#374151' }}>Progreso</Text>
              <Text style={{ fontSize: 13, fontWeight: '700', color: '#2D6A4F' }}>{dashboard.progress}%</Text>
            </View>
            <ProgressBar progress={dashboard.progress} />
            <Text style={{ fontSize: 11, color: '#9CA3AF', marginTop: 6 }}>
              Objetivo: {formatCurrency(profile.targetAmount)}
            </Text>
          </Card>
        )}

        {/* Quick actions */}
        <View style={styles.actionsRow}>
          {[
            { icon: '⚙️', label: 'Ajustes', route: '/(cause)/settings' },
          ].map(({ icon, label, route }) => (
            <TouchableOpacity key={route} style={styles.actionBtn} onPress={() => router.push(route as any)}>
              <Text style={styles.actionIcon}>{icon}</Text>
              <Text style={styles.actionLabel}>{label}</Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* Donations to confirm */}
        {paidDonations.length > 0 && (
          <>
            <Text style={styles.sectionTitle}>
              Pagos para confirmar{' '}
              <Text style={{ color: '#1D4ED8' }}>({paidDonations.length})</Text>
            </Text>
            {paidDonations.map(d => (
              <Card key={d.id}>
                <View style={{ flexDirection: 'row', alignItems: 'center', gap: 12 }}>
                  <View style={{ flex: 1 }}>
                    <Text style={{ fontSize: 14, fontWeight: '700', color: '#111827' }}>{d.restaurant?.name}</Text>
                    <Text style={{ fontSize: 12, color: '#9CA3AF', marginTop: 2 }}>{d.order?.createdAt ? formatDate(d.order.createdAt) : ''}</Text>
                    {d.notes && <Text style={{ fontSize: 12, color: '#6B7280', fontStyle: 'italic', marginTop: 2 }}>"{d.notes}"</Text>}
                  </View>
                  <View style={{ alignItems: 'flex-end', gap: 8 }}>
                    <Text style={{ fontSize: 17, fontWeight: '800', color: '#059669' }}>{formatCurrency(d.amount)}</Text>
                    <TouchableOpacity
                      style={{ backgroundColor: '#2D6A4F', paddingHorizontal: 12, paddingVertical: 6, borderRadius: 8 }}
                      onPress={() => confirm(d.id)}
                      disabled={confirming === d.id}
                    >
                      <Text style={{ color: '#fff', fontSize: 12, fontWeight: '700' }}>
                        {confirming === d.id ? '...' : 'Confirmar'}
                      </Text>
                    </TouchableOpacity>
                  </View>
                </View>
              </Card>
            ))}
          </>
        )}

        {/* Recent activity */}
        {dashboard?.recentDonations?.length > 0 && (
          <>
            <Text style={styles.sectionTitle}>Actividad reciente</Text>
            {dashboard.recentDonations.map((d: any) => (
              <Card key={d.id}>
                <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' }}>
                  <View>
                    <Text style={{ fontSize: 13, fontWeight: '600', color: '#111827' }}>{d.restaurant?.name}</Text>
                    <Text style={{ fontSize: 11, color: '#9CA3AF', marginTop: 2 }}>{formatDate(d.order?.createdAt || d.createdAt)}</Text>
                  </View>
                  <View style={{ alignItems: 'flex-end', gap: 4 }}>
                    <Text style={{ fontSize: 14, fontWeight: '700' }}>{formatCurrency(d.amount)}</Text>
                    <Badge status={d.status} />
                  </View>
                </View>
              </Card>
            ))}
          </>
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
  logo: { fontSize: 20, fontWeight: '800', color: '#2D6A4F' },
  headerSub: { fontSize: 11, color: '#9CA3AF', marginTop: -2 },
  causeName: { fontSize: 22, fontWeight: '800', color: '#111827' },
  causeRestaurants: { fontSize: 13, color: '#2D6A4F', fontWeight: '500', marginTop: 3 },
  statsRow: { flexDirection: 'row', gap: 8, marginBottom: 8 },
  statCard: {
    backgroundColor: '#fff', borderRadius: 14, padding: 14,
    shadowColor: '#000', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.05, shadowRadius: 3, elevation: 2,
  },
  statValue: { fontSize: 18, fontWeight: '800', marginBottom: 3 },
  statLabel: { fontSize: 11, color: '#6B7280' },
  progressContainer: { height: 10, backgroundColor: '#E5E7EB', borderRadius: 10, overflow: 'hidden' },
  progressFill: { height: 10, backgroundColor: '#2D6A4F', borderRadius: 10 },
  actionsRow: {
    backgroundColor: '#fff', borderRadius: 16, padding: 8, marginVertical: 12,
    shadowColor: '#000', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.05, shadowRadius: 4, elevation: 2,
    flexDirection: 'row',
  },
  actionBtn: { flex: 1, alignItems: 'center', padding: 10 },
  actionIcon: { fontSize: 22, marginBottom: 4 },
  actionLabel: { fontSize: 11, color: '#374151', fontWeight: '500' },
  sectionTitle: { fontSize: 15, fontWeight: '700', color: '#111827', marginBottom: 8, marginTop: 4 },
})
