import { TouchableOpacity, Text, ActivityIndicator, StyleSheet, ViewStyle } from 'react-native'

interface Props {
  label: string
  onPress: () => void
  variant?: 'primary' | 'secondary' | 'danger' | 'ghost'
  loading?: boolean
  disabled?: boolean
  style?: ViewStyle
}

const VARIANTS = {
  primary:   { bg: '#2D6A4F', text: '#ffffff', border: '#2D6A4F' },
  secondary: { bg: '#ffffff', text: '#2D6A4F', border: '#2D6A4F' },
  danger:    { bg: '#DC2626', text: '#ffffff', border: '#DC2626' },
  ghost:     { bg: 'transparent', text: '#2D6A4F', border: 'transparent' },
}

export default function Button({ label, onPress, variant = 'primary', loading, disabled, style }: Props) {
  const v = VARIANTS[variant]
  return (
    <TouchableOpacity
      onPress={onPress}
      disabled={disabled || loading}
      style={[
        styles.base,
        { backgroundColor: v.bg, borderColor: v.border },
        (disabled || loading) && { opacity: 0.5 },
        style,
      ]}
      activeOpacity={0.8}
    >
      {loading
        ? <ActivityIndicator color={v.text} size="small" />
        : <Text style={[styles.label, { color: v.text }]}>{label}</Text>
      }
    </TouchableOpacity>
  )
}

const styles = StyleSheet.create({
  base: {
    height: 48,
    borderRadius: 12,
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 16,
  },
  label: {
    fontSize: 15,
    fontWeight: '600',
  },
})
