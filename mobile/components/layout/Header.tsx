import { View, Text, TouchableOpacity, StyleSheet } from 'react-native'
import { useSafeAreaInsets } from 'react-native-safe-area-context'
import { useRouter } from 'expo-router'

interface Props {
  title: string
  showBack?: boolean
  right?: React.ReactNode
}

export default function Header({ title, showBack, right }: Props) {
  const insets = useSafeAreaInsets()
  const router = useRouter()

  return (
    <View style={[styles.container, { paddingTop: insets.top + 8 }]}>
      <View style={styles.row}>
        {showBack ? (
          <TouchableOpacity onPress={() => router.back()} style={styles.back}>
            <Text style={styles.backText}>←</Text>
          </TouchableOpacity>
        ) : (
          <Text style={styles.logo}>Unitia</Text>
        )}
        <Text style={styles.title}>{title}</Text>
        <View style={styles.rightSlot}>{right}</View>
      </View>
    </View>
  )
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#ffffff',
    borderBottomWidth: 1,
    borderBottomColor: '#F3F4F6',
    paddingHorizontal: 16,
    paddingBottom: 12,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  logo: { fontSize: 18, fontWeight: '800', color: '#2D6A4F', width: 60 },
  back: { width: 60 },
  backText: { fontSize: 20, color: '#6B7280' },
  title: { fontSize: 16, fontWeight: '700', color: '#111827', flex: 1, textAlign: 'center' },
  rightSlot: { width: 60, alignItems: 'flex-end' },
})
