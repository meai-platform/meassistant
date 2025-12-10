package com.example.meai_assistant_example

import android.content.pm.PackageManager
import android.content.pm.PackageInfo
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    // No platform channel needed for Android - keystore_signature package handles app signature
    // iOS uses a simple platform channel for team ID only
}
