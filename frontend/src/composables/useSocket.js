import { io } from 'socket.io-client'

let _socket = null
const _listeners = new Map()

export function useSocket() {
  function connect() {
    if (_socket?.connected) return
    const token = localStorage.getItem('access_token')
    if (!token) return

    const url = import.meta.env.VITE_API_URL || window.location.origin

    _socket = io(url, {
      path: '/socket.io/',
      auth: { token },
      transports: ['websocket', 'polling'],
      reconnection: true,
      reconnectionDelay: 5000,
      reconnectionAttempts: 10,
    })

    _socket.on('connect', () => console.log('[Socket] connected:', _socket.id))
    _socket.on('disconnect', (r) => console.log('[Socket] disconnected:', r))
    _socket.on('connect_error', (e) => console.warn('[Socket] error:', e.message))

    // Re-register any listeners added before connect
    _listeners.forEach((cb, event) => _socket.on(event, cb))
  }

  function on(event, callback) {
    _listeners.set(event, callback)
    _socket?.on(event, callback)
  }

  function off(event) {
    _socket?.off(event)
    _listeners.delete(event)
  }

  function disconnect() {
    _socket?.disconnect()
    _socket = null
    _listeners.clear()
  }

  return { connect, disconnect, on, off }
}
