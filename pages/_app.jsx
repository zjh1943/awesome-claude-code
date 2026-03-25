import { Analytics } from '@vercel/analytics/react'
import Script from 'next/script'
import FloatingWidget from '../components/FloatingWidget'
import '../styles/global.css'

export default function App({ Component, pageProps }) {
  return (
    <>
      <Component {...pageProps} />
      <FloatingWidget />
      <Analytics />
      <Script
        src="https://webot.ai-code.club/static/widget/src/widget.js"
        data-api-url="https://webot.ai-code.club"
        data-kf-url="https://work.weixin.qq.com/kfid/kfcfa0cc825783bd3f4"
        data-primary-color="#10b981"
        data-title="CC Club 助手"
        strategy="afterInteractive"
      />
    </>
  )
}
