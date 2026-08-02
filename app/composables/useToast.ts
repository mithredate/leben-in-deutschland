export const useToast = () => {
  const message = useState<string>('toast-message', () => '')
  const visible = useState<boolean>('toast-visible', () => false)
  const timer = useState<ReturnType<typeof setTimeout> | null>('toast-timer', () => null)

  function show(msg: string) {
    message.value = msg
    visible.value = true
    if (timer.value) clearTimeout(timer.value)
    timer.value = setTimeout(() => (visible.value = false), 2200)
  }

  return { message, visible, show }
}
