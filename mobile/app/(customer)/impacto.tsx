import { useState } from 'react'
import { View, Text, StyleSheet, ScrollView, TextInput, TouchableOpacity, ActivityIndicator, Alert } from 'react-native'
import { useSafeAreaInsets } from 'react-native-safe-area-context'
import { api } from '../../lib/api'
import { formatCurrency, formatDate } from '../../lib/auth'
import Card from '../../components/ui/Card'
import Button from '../../components/ui/Button'

export default function ImpactoScreen() {
  const insets = useSafeAreaInsets()
  const [email, setEmail] = useState('')
  const [data, setData] = useState<any>(null)
  const [loading, setLoading] = useState(false)
  const [searched, setSearched] = useState(false)

  async function search() {
    if (!email.includes('@')) { Alert.alert('Email inválido', 'Ingresá un email válido.'); return }
    setLoading(true)
    setData(null)
    try {
      const res = await api.public.getImpact(email)
      setData(res.data)
      setSearched(true)
    } catch (err: any) {
      Alert.alert('Error', err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <View style={{ flex: 1, backgroundColor: '#F9FAFB' }}>
      <View style={[styles.header, { paddingTop: insets.top + 12 }]}>
        <Text style={styles.logo}>Unitia</Text>
        <Text style={styles.headerTitle}>Mi impacto</Text>
      </View>

      <ScrollView contentContainerStyle={{ padding: 16, paddingBottom: insets.bottom + 24 }} keyboardShouldPersistTaps="handled">
        <View style={styles.hero}>
          <Text style={styles.heroEmoji}>🌱</Text>
          <Text style={styles.heroTitle}>¿Cuánto donaste?</Text>
          <Text style={styles.heroSub}>Ingresá el email que usaste al pedir y te mostramos tu impacto real.</Text>
        </View>

        <Card>
          <Text style={styles.inputLabel}>Tu email</Text>
          <View style={styles.inputRow}>
            <TextInput
              style={styles.input}
              value={email}
              onChangeText={setEmail}
              placeholder="tu@email.com"
              placeholderTextColor="#9CA3AF"
              keyboardType="email-address"
              autoCapitalize="none"
              autoComplete="email"
              returnKeyType="search"
              onSubmitEditing={search}
            />
          </View>
          <Button label={loading ? 'Buscando...' : 'Ver mi impacto'} onPress={search} loading={loading} style={{ marginTop: 10 }} />
        </Card>

        {searched && data?.totalOrders === 0 && (
          <Card>
            <View style={{ alignItems: 'center', paddingVertical: 20 }}>
              <Text style={{ fontSize: 36, marginBottom: 10 }}>😔</Text>
              <Text style={{ fontSize: 15, fontWeight: '600', color: '#374151', marginBottom: 6 }}>Sin pedidos encontrados</Text>
              <Text style={{ fontSize: 13, color: '#9CA3AF', textAlign: 'center' }}>
                Cuando hagas un pedido en un restaurante Unitia ingresando tu email, aparecerá aquí.
              </Text>
            </View>
          </Card>
        )}

        {searched && data && data.totalOrders > 0 && (
          <>
            {/* Summary */}
            <View style={styles.summaryRow}>
              <View style={[styles.summaryCard, { flex: 1 }]}>
                <Text style={styles.summaryValue}>{formatCurrency(data.totalDonated)}</Text>
                <Text style={styles.summaryLabel}>donado en total</Text>
              </View>
              <View style={[styles.summaryCard, { flex: 1 }]}>
                <Text style={[styles.summaryValue, { color: '#374151' }]}>{data.totalOrders}</Text>
                <Text style={styles.summaryLabel}>pedidos realizados</Text>
              </View>
            </View>

            {/* By cause */}
            <Text style={styles.sectionTitle}>Por causa</Text>
            {data.byCause.map((item: any) => (
              <Card key={item.cause.id}>
                <View style={{ flexDirection: 'row', alignItems: 'center', gap: 12 }}>
                  <View style={styles.causeAvatar}>
                    <Text style={styles.causeAvatarText}>{item.cause.name[0]}</Text>
                  </View>
                  <View style={{ flex: 1 }}>
                    <Text style={{ fontSize: 14, fontWeight: '700', color: '#111827' }}>{item.cause.name}</Text>
                    <Text style={{ fontSize: 12, color: '#9CA3AF' }}>{item.orderCount} pedido{item.orderCount !== 1 ? 's' : ''}</Text>
                  </View>
                  <View style={{ alignItems: 'flex-end' }}>
                    <Text style={{ fontSize: 16, fontWeight: '800', color: '#2D6A4F' }}>{formatCurrency(item.totalDonated)}</Text>
                    <Text style={{ fontSize: 11, color: '#9CA3AF' }}>donado</Text>
                  </View>
                </View>
              </Card>
            ))}

            {/* Recent orders */}
            <Text style={styles.sectionTitle}>Historial reciente</Text>
            {data.recentOrders.map((order: any) => (
              <Card key={order.id}>
                <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <View style={{ flex: 1 }}>
                    <Text style={{ fontSize: 13, fontWeight: '700', color: '#111827' }}>{order.restaurant?.name}</Text>
                    <Text style={{ fontSize: 11, color: '#9CA3AF', marginTop: 2 }}>→ {order.cause?.name}</Text>
                    <Text style={{ fontSize: 11, color: '#9CA3AF', marginTop: 1 }}>{formatDate(order.date)}</Text>
                  </View>
                  <View style={{ alignItems: 'flex-end' }}>
                    <Text style={{ fontSize: 13, color: '#374151', fontWeight: '500' }}>{formatCurrency(order.subtotal)}</Text>
                    <Text style={{ fontSize: 12, color: '#059669', fontWeight: '700', marginTop: 2 }}>+{formatCurrency(order.donationAmount)}</Text>
                  </View>
                </View>
              </Card>
            ))}

            <Text style={{ textAlign: 'center', fontSize: 12, color: '#9CA3AF', marginTop: 8 }}>
              Gracias por elegir restaurantes que hacen el bien 💚
            </Text>
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
    flexDirection: 'row', alignItems: 'center', gap: 8,
  },
  logo: { fontSize: 20, fontWeight: '800', color: '#2D6A4F' },
  headerTitle: { fontSize: 15, fontWeight: '600', color: '#374151' },
  hero: { alignItems: 'center', paddingVertical: 24 },
  heroEmoji: { fontSize: 48, marginBottom: 10 },
  heroTitle: { fontSize: 22, fontWeight: '800', color: '#111827', marginBottom: 6 },
  heroSub: { fontSize: 14, color: '#6B7280', textAlign: 'center', lineHeight: 20 },
  inputLabel: { fontSize: 13, fontWeight: '600', color: '#374151', marginBottom: 6 },
  inputRow: { flexDirection: 'row', gap: 8 },
  input: {
    flex: 1, height: 46, backgroundColor: '#F9FAFB',
    borderWidth: 1, borderColor: '#D1D5DB', borderRadius: 10,
    paddingHorizontal: 12, fontSize: 15, color: '#111827',
  },
  summaryRow: { flexDirection: 'row', gap: 8, marginBottom: 12 },
  summaryCard: {
    backgroundColor: '#fff', borderRadius: 14, padding: 14,
    shadowColor: '#000', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.05, shadowRadius: 3, elevation: 2,
    alignItems: 'center',
  },
  summaryValue: { fontSize: 20, fontWeight: '800', color: '#2D6A4F', marginBottom: 3 },
  summaryLabel: { fontSize: 11, color: '#9CA3AF', textAlign: 'center' },
  sectionTitle: { fontSize: 15, fontWeight: '700', color: '#111827', marginBottom: 8, marginTop: 4 },
  causeAvatar: {
    width: 38, height: 38, borderRadius: 19,
    backgroundColor: '#D1EBDF', alignItems: 'center', justifyContent: 'center',
  },
  causeAvatarText: { fontSize: 16, fontWeight: '800', color: '#2D6A4F' },
})
