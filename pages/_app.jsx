import { Analytics } from '@vercel/analytics/react'
import FloatingWidget from '../components/FloatingWidget'
import '../styles/global.css'

export default function App({ Component, pageProps }) {
  return (
    <>
      <Component {...pageProps} />
      <FloatingWidget />
      <Analytics />
    </>
  )
}
