package com.example.pds_weight_machine

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val methodChannel = "com.example.pds_weight_machine/bt"
    private val eventChannel = "com.example.pds_weight_machine/bt_events"
    private var bluetoothSppServer: BluetoothSppServer? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        bluetoothSppServer = BluetoothSppServer(this)
        setupChannels()
    }

    private fun setupChannels() {
        val messenger = flutterEngine?.dartExecutor?.binaryMessenger ?: return

        MethodChannel(messenger, methodChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "startBluetoothServer" -> {
                    bluetoothSppServer?.startServer()
                    result.success(null)
                }
                "stopBluetoothServer" -> {
                    bluetoothSppServer?.stopServer()
                    result.success(null)
                }
                "isBluetoothEnabled" -> {
                    result.success(bluetoothSppServer?.isBluetoothEnabled() ?: false)
                }
                "sendData" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    if (bytes != null) {
                        val success = bluetoothSppServer?.sendData(bytes)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "Bytes array is null", null)
                    }
                }
                "disconnect" -> {
                    bluetoothSppServer?.disconnect(notifyWaiting = true)
                    result.success(null)
                }
                "requestEnableBluetooth" -> {
                    val intent = android.content.Intent(android.bluetooth.BluetoothAdapter.ACTION_REQUEST_ENABLE)
                    try {
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Cannot request Bluetooth enable", e.message)
                    }
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, eventChannel).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                bluetoothSppServer?.setEventSink(events)
            }

            override fun onCancel(arguments: Any?) {
                bluetoothSppServer?.setEventSink(null)
            }
        })
    }

    override fun onDestroy() {
        bluetoothSppServer?.dispose()
        super.onDestroy()
    }
}
