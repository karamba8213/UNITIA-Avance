import './globals.css'
import Providers from './providers'

export const metadata = {
  title: 'Unitia — Cada pedido suma',
  description: 'Plataforma que conecta restaurantes con causas sociales. Cada orden genera una donación automática.',
  openGraph: {
    title: 'Unitia — Cada pedido suma',
    description: 'Conectamos restaurantes con causas sociales. Come bien, haz el bien.',
    type: 'website',
  },
}

export default function RootLayout({ children }) {
  return (
    <html lang="es">
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  )
}
