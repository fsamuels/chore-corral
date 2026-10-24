export interface ToastAction {
  label: string
  onClick: () => void
}

export interface ToastOptions {
  action?: ToastAction
  /** Milliseconds before auto-dismiss. Defaults to 4000. */
  timeout?: number
  tone?: 'default' | 'error'
}

export interface ToastState {
  /** Bumped on every showToast so a replacement restarts the timer. */
  id: number
  message: string
  action: ToastAction | null
  timeout: number
  tone: 'default' | 'error'
  open: boolean
}

const DEFAULT_TIMEOUT_MS = 4000

/**
 * App-wide toast. State lives in `useState` so any component can raise one
 * and the single `AppToast` in the default layout renders it. A new toast
 * replaces the current one rather than queueing.
 */
export function useToast() {
  const toast = useState<ToastState>('app-toast', () => ({
    id: 0,
    message: '',
    action: null,
    timeout: DEFAULT_TIMEOUT_MS,
    tone: 'default',
    open: false,
  }))

  function showToast(message: string, opts: ToastOptions = {}): void {
    toast.value = {
      id: toast.value.id + 1,
      message,
      action: opts.action ?? null,
      timeout: opts.timeout ?? DEFAULT_TIMEOUT_MS,
      tone: opts.tone ?? 'default',
      open: true,
    }
  }

  function hideToast(): void {
    toast.value = { ...toast.value, open: false }
  }

  return { toast, showToast, hideToast }
}
