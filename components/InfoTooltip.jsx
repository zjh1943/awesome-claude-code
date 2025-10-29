import * as Tooltip from '@radix-ui/react-tooltip'
import { Info } from 'lucide-react'

export default function InfoTooltip({ content, children }) {
  return (
    <Tooltip.Provider delayDuration={200}>
      <Tooltip.Root>
        <Tooltip.Trigger asChild>
          <span
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              cursor: 'help',
              marginLeft: '4px',
              verticalAlign: 'middle'
            }}
          >
            {children || <Info size={14} style={{ opacity: 0.7 }} />}
          </span>
        </Tooltip.Trigger>
        <Tooltip.Portal>
          <Tooltip.Content
            className="info-tooltip-content"
            sideOffset={5}
            style={{
              backgroundColor: 'rgba(0, 0, 0, 0.9)',
              color: 'white',
              padding: '8px 12px',
              borderRadius: '6px',
              fontSize: '13px',
              lineHeight: '1.5',
              maxWidth: '300px',
              zIndex: 9999,
              boxShadow: '0 4px 12px rgba(0, 0, 0, 0.15)'
            }}
          >
            {content}
            <Tooltip.Arrow
              style={{
                fill: 'rgba(0, 0, 0, 0.9)'
              }}
            />
          </Tooltip.Content>
        </Tooltip.Portal>
      </Tooltip.Root>
    </Tooltip.Provider>
  )
}
