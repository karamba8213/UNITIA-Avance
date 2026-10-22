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
      <head>
        <link
          rel="preconnect"
          href="https://fonts.googleapis.com"
        />
        <link
          rel="preconnect"
          href="https://fonts.gstatic.com"
          crossOrigin="anonymous"
        />
        <link
          href="https://fonts.googleapis.com/css2?family=Manrope:wght@400;500;600;700;800&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap"
          rel="stylesheet"
        />
      </head>
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  )
}
