package com.example.pds_weight_machine

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothServerSocket
import android.bluetooth.BluetoothSocket
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.EventChannel
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.util.UUID

class BluetoothSppServer(private val context: Context) {

    private val tag = "BluetoothSppServer"
    private val serviceName = "WeightMachineBT"
    private val uuid = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

    private var bluetoothAdapter: BluetoothAdapter? = null
    private var serverSocket: BluetoothServerSocket? = null
    private var activeSocket: BluetoothSocket? = null
    private var inputStream: InputStream? = null
    private var outputStream: OutputStream? = null

    private var acceptThread: Thread? = null
    private var readThread: Thread? = null

    @Volatile private var isServerRunning = false
    @Volatile private var isConnected = false

    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private val bluetoothReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == BluetoothAdapter.ACTION_STATE_CHANGED) {
                val state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR)
                when (state) {
                    BluetoothAdapter.STATE_OFF -> {
                        Log.d(tag, "Bluetooth disabled")
                        sendEvent("state_changed", "bluetooth_disabled")
                        stopServer()
                    }
                    BluetoothAdapter.STATE_ON -> {
                        Log.d(tag, "Bluetooth enabled")
                        sendEvent("state_changed", "bluetooth_enabled")
                        // Wait for Flutter to tell us to start, or auto-start? 
                        // Flutter controls `requestEnable` and then calls `startBluetoothServer()`
                    }
                }
            }
        }
    }

    init {
        val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        bluetoothAdapter = bluetoothManager.adapter
        context.registerReceiver(bluetoothReceiver, IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED))
    }

    fun setEventSink(sink: EventChannel.EventSink?) {
        this.eventSink = sink
        sendEvent("status", getStatus())
    }

    private fun sendEvent(type: String, data: Any) {
        mainHandler.post {
            eventSink?.success(mapOf("type" to type, "data" to data))
        }
    }

    fun getStatus(): String {
        if (!isBluetoothEnabled()) return "bluetooth_disabled"
        if (isConnected) return "connected"
        if (isServerRunning) return "waiting"
        return "bluetooth_enabled"
    }

    fun isBluetoothEnabled(): Boolean {
        return bluetoothAdapter?.isEnabled == true
    }

    @SuppressLint("MissingPermission")
    fun startServer() {
        if (bluetoothAdapter == null || !bluetoothAdapter!!.isEnabled) {
            Log.e(tag, "Bluetooth is not enabled or available")
            return
        }

        if (isServerRunning) {
            Log.w(tag, "Server is already running")
            return
        }

        try {
            serverSocket = bluetoothAdapter?.listenUsingInsecureRfcommWithServiceRecord(serviceName, uuid)
            isServerRunning = true
            sendEvent("state_changed", "waiting")
            Log.d(tag, "SPP server started. Waiting for connection...")

            acceptThread = Thread {
                while (isServerRunning) {
                    var socket: BluetoothSocket? = null
                    try {
                        socket = serverSocket?.accept()
                    } catch (e: IOException) {
                        if (isServerRunning) {
                            Log.e(tag, "Socket accept() failed", e)
                        }
                        break
                    }

                    if (socket != null) {
                        Log.d(tag, "RFCOMM connection accepted")
                        manageConnectedSocket(socket)
                    }
                }
            }
            acceptThread?.start()
        } catch (e: IOException) {
            Log.e(tag, "Failed to start SPP Server", e)
            sendEvent("error", "server_start_failed")
        }
    }

    @Synchronized
    private fun manageConnectedSocket(socket: BluetoothSocket) {
        disconnect(notifyWaiting = false) // Close previous safely

        activeSocket = socket
        try {
            inputStream = socket.inputStream
            outputStream = socket.outputStream
            isConnected = true
            sendEvent("state_changed", "connected")
            Log.d(tag, "Bluetooth device connected")

            readThread = Thread {
                val buffer = ByteArray(1024)
                while (isConnected) {
                    try {
                        val bytes = inputStream?.read(buffer) ?: -1
                        if (bytes > 0) {
                            val data = buffer.copyOfRange(0, bytes).toList()
                            sendEvent("data_received", data)
                        } else if (bytes == -1) {
                            Log.d(tag, "End of stream")
                            break
                        }
                    } catch (e: IOException) {
                        Log.e(tag, "Input stream read failed", e)
                        break
                    }
                }
                Log.d(tag, "Read thread exiting")
                disconnect(notifyWaiting = true)
            }
            readThread?.start()
        } catch (e: IOException) {
            Log.e(tag, "Error setting up streams", e)
            disconnect(notifyWaiting = true)
        }
    }

    fun sendData(data: ByteArray): Boolean {
        if (!isConnected || outputStream == null) {
            return false
        }
        return try {
            outputStream?.write(data)
            outputStream?.flush()
            true
        } catch (e: IOException) {
            Log.e(tag, "Error writing data", e)
            disconnect(notifyWaiting = true)
            false
        }
    }

    @Synchronized
    fun disconnect(notifyWaiting: Boolean = true) {
        if (!isConnected && activeSocket == null) return
        isConnected = false
        try { inputStream?.close() } catch (e: IOException) {}
        try { outputStream?.close() } catch (e: IOException) {}
        try { activeSocket?.close() } catch (e: IOException) {}
        
        inputStream = null
        outputStream = null
        activeSocket = null
        
        Log.d(tag, "Bluetooth device disconnected")
        
        if (notifyWaiting && isServerRunning) {
            sendEvent("state_changed", "waiting")
        }
    }

    @Synchronized
    fun stopServer() {
        isServerRunning = false
        disconnect(notifyWaiting = false)
        try {
            serverSocket?.close()
        } catch (e: IOException) {
            Log.e(tag, "Error closing server socket", e)
        }
        serverSocket = null
        Log.d(tag, "SPP server stopped")
        sendEvent("state_changed", getStatus())
    }

    fun dispose() {
        context.unregisterReceiver(bluetoothReceiver)
        stopServer()
    }
}
