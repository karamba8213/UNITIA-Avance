import { useEffect, useState } from 'react'
import { View, Text, StyleSheet, FlatList, TouchableOpacity, Modal, Alert, TextInput, Switch, RefreshControl } from 'react-native'
import { useSafeAreaInsets } from 'react-native-safe-area-context'
import { useRouter } from 'expo-router'
import { api } from '../../lib/api'
import { useAuth } from '../../lib/context'
import { formatCurrency } from '../../lib/auth'
import Header from '../../components/layout/Header'
import Button from '../../components/ui/Button'

const EMPTY = { name: '', description: '', price: '', category: '', imageUrl: '', isAvailable: true }

export default function MenuScreen() {
  const insets = useSafeAreaInsets()
  const router = useRouter()
  const { logout } = useAuth()
  const [items, setItems] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [showModal, setShowModal] = useState(false)
  const [editing, setEditing] = useState<string | null>(null)
  const [form, setForm] = useState<any>(EMPTY)
  const [saving, setSaving] = useState(false)

  useEffect(() => { load() }, [])

  async function load() {
    try {
      const res = await api.restaurant.getMenu()
      setItems(res.data || [])
    } catch (err: any) {
      if (err.status === 401) { await logout(); router.replace('/(auth)/login') }
    } finally {
      setLoading(false)
      setRefreshing(false)
    }
  }

  function openNew() {
    setForm(EMPTY)
    setEditing(null)
    setShowModal(true)
  }

  function openEdit(item: any) {
    setForm({ ...item, price: String(item.price), description: item.description || '', category: item.category || '', imageUrl: item.imageUrl || '' })
    setEditing(item.id)
    setShowModal(true)
  }

  async function save() {
    if (!form.name || !form.price) {
      Alert.alert('Requerido', 'Nombre y precio son obligatorios.')
      return
    }
    setSaving(true)
    try {
      const payload = { ...form, price: parseFloat(form.price) }
      if (editing) await api.restaurant.updateMenuItem(editing, payload)
      else await api.restaurant.createMenuItem(payload)
      setShowModal(false)
      load()
    } catch (err: any) {
      Alert.alert('Error', err.message)
    } finally {
      setSaving(false)
    }
  }

  async function disable(id: string) {
    Alert.alert('Deshabilitar', '¿Deshabilitar este item del menú?', [
      { text: 'Cancelar', style: 'cancel' },
      { text: 'Deshabilitar', style: 'destructive', onPress: async () => {
        try {
          await api.restaurant.deleteMenuItem(id)
          load()
        } catch (err: any) { Alert.alert('Error', err.message) }
      }},
    ])
  }

  const grouped = items.reduce((map: any, item: any) => {
    const cat = item.category || 'Sin categoría'
    if (!map[cat]) map[cat] = []
    map[cat].push(item)
    return map
  }, {})

  return (
    <View style={{ flex: 1, backgroundColor: '#F9FAFB' }}>
      <Header
        title="Menú"
        showBack
        right={
          <TouchableOpacity onPress={openNew} style={styles.addBtn}>
            <Text style={styles.addBtnText}>+ Agregar</Text>
          </TouchableOpacity>
        }
      />

      <FlatList
        data={Object.entries(grouped)}
        keyExtractor={([cat]) => cat}
        contentContainerStyle={{ padding: 16, paddingBottom: insets.bottom + 24 }}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => { setRefreshing(true); load() }} tintColor="#2D6A4F" />}
        ListEmptyComponent={
          !loading ? (
            <View style={{ alignItems: 'center', paddingTop: 60 }}>
              <Text style={{ fontSize: 40, marginBottom: 12 }}>🍽</Text>
              <Text style={{ color: '#6B7280', marginBottom: 16 }}>Tu menú está vacío.</Text>
              <Button label="Agregar primer plato" onPress={openNew} style={{ paddingHorizontal: 24 }} />
            </View>
          ) : null
        }
        renderItem={({ item: [cat, catItems] }) => (
          <View style={{ marginBottom: 16 }}>
            <Text style={styles.category}>{cat as string}</Text>
            {(catItems as any[]).map((item: any) => (
              <View key={item.id} style={[styles.card, !item.isAvailable && { opacity: 0.45 }]}>
                <View style={{ flex: 1 }}>
                  <Text style={styles.itemName}>{item.name}</Text>
                  {item.description ? <Text style={styles.itemDesc} numberOfLines={1}>{item.description}</Text> : null}
                  <Text style={styles.itemPrice}>{formatCurrency(item.price)}</Text>
                </View>
                <View style={{ gap: 8 }}>
                  <TouchableOpacity onPress={() => openEdit(item)} style={styles.editBtn}>
                    <Text style={styles.editBtnText}>Editar</Text>
                  </TouchableOpacity>
                  {item.isAvailable && (
                    <TouchableOpacity onPress={() => disable(item.id)} style={styles.disableBtn}>
                      <Text style={styles.disableBtnText}>Quitar</Text>
                    </TouchableOpacity>
                  )}
                </View>
              </View>
            ))}
          </View>
        )}
      />

      {/* Form modal */}
      <Modal visible={showModal} animationType="slide" presentationStyle="pageSheet">
        <View style={{ flex: 1, backgroundColor: '#F9FAFB' }}>
          <View style={[styles.modalHeader, { paddingTop: insets.top + 8 }]}>
            <TouchableOpacity onPress={() => setShowModal(false)}>
              <Text style={{ color: '#6B7280', fontSize: 15 }}>Cancelar</Text>
            </TouchableOpacity>
            <Text style={styles.modalTitle}>{editing ? 'Editar item' : 'Nuevo item'}</Text>
            <TouchableOpacity onPress={save} disabled={saving}>
              <Text style={{ color: '#2D6A4F', fontSize: 15, fontWeight: '700' }}>{saving ? '...' : 'Guardar'}</Text>
            </TouchableOpacity>
          </View>

          <FlatList
            data={[{ key: 'form' }]}
            keyExtractor={i => i.key}
            contentContainerStyle={{ padding: 20 }}
            keyboardShouldPersistTaps="handled"
            renderItem={() => (
              <View style={styles.formCard}>
                {[
                  { label: 'Nombre *', key: 'name', placeholder: 'Ej: Milanesa napolitana' },
                  { label: 'Precio *', key: 'price', placeholder: '1500', keyboard: 'decimal-pad' },
                  { label: 'Categoría', key: 'category', placeholder: 'Platos principales' },
                  { label: 'Descripción', key: 'description', placeholder: 'Con papas fritas y ensalada', multiline: true },
                  { label: 'URL de imagen', key: 'imageUrl', placeholder: 'https://...', keyboard: 'url' },
                ].map(field => (
                  <View key={field.key} style={{ marginBottom: 14 }}>
                    <Text style={styles.fieldLabel}>{field.label}</Text>
                    <TextInput
                      style={[styles.fieldInput, field.multiline && { height: 72, textAlignVertical: 'top', paddingTop: 10 }]}
                      value={form[field.key]}
                      onChangeText={v => setForm((f: any) => ({ ...f, [field.key]: v }))}
                      placeholder={field.placeholder}
                      placeholderTextColor="#9CA3AF"
                      keyboardType={(field as any).keyboard || 'default'}
                      multiline={field.multiline}
                    />
                  </View>
                ))}
                {editing && (
                  <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginTop: 4 }}>
                    <Text style={styles.fieldLabel}>Disponible</Text>
                    <Switch
                      value={form.isAvailable}
                      onValueChange={v => setForm((f: any) => ({ ...f, isAvailable: v }))}
                      trackColor={{ true: '#2D6A4F' }}
                    />
                  </View>
                )}
              </View>
            )}
          />
        </View>
      </Modal>
    </View>
  )
}

const styles = StyleSheet.create({
  addBtn: { backgroundColor: '#2D6A4F', paddingHorizontal: 10, paddingVertical: 5, borderRadius: 8 },
  addBtnText: { color: '#fff', fontSize: 12, fontWeight: '700' },
  category: { fontSize: 12, fontWeight: '700', color: '#6B7280', textTransform: 'uppercase', letterSpacing: 0.8, marginBottom: 8 },
  card: {
    backgroundColor: '#fff', borderRadius: 14, padding: 14, marginBottom: 8,
    flexDirection: 'row', gap: 12,
    shadowColor: '#000', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.05, shadowRadius: 3, elevation: 2,
  },
  itemName: { fontSize: 14, fontWeight: '700', color: '#111827', marginBottom: 2 },
  itemDesc: { fontSize: 12, color: '#9CA3AF', marginBottom: 4 },
  itemPrice: { fontSize: 15, fontWeight: '800', color: '#2D6A4F' },
  editBtn: { backgroundColor: '#F3F4F6', paddingHorizontal: 10, paddingVertical: 5, borderRadius: 8 },
  editBtnText: { fontSize: 11, fontWeight: '600', color: '#374151' },
  disableBtn: { backgroundColor: '#FEE2E2', paddingHorizontal: 10, paddingVertical: 5, borderRadius: 8 },
  disableBtnText: { fontSize: 11, fontWeight: '600', color: '#DC2626' },
  modalHeader: {
    flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center',
    paddingHorizontal: 20, paddingBottom: 12,
    backgroundColor: '#fff', borderBottomWidth: 1, borderBottomColor: '#F3F4F6',
  },
  modalTitle: { fontSize: 16, fontWeight: '700', color: '#111827' },
  formCard: {
    backgroundColor: '#fff', borderRadius: 16, padding: 16,
    shadowColor: '#000', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.05, shadowRadius: 4, elevation: 2,
  },
  fieldLabel: { fontSize: 13, fontWeight: '600', color: '#374151', marginBottom: 5 },
  fieldInput: {
    height: 44, backgroundColor: '#F9FAFB', borderWidth: 1, borderColor: '#D1D5DB',
    borderRadius: 10, paddingHorizontal: 12, fontSize: 14, color: '#111827',
  },
})
