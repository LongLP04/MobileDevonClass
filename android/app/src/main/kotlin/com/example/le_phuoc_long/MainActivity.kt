package com.example.le_phuoc_long

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
// Đảm bảo import này được sử dụng để gọi phương thức đăng ký plugin
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {

    // Phương thức này ghi đè lên phương thức của FlutterActivity
    // Nó đảm bảo các plugin được đăng ký ngay khi Flutter Engine khởi tạo
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        // Gọi hàm đăng ký để kích hoạt tất cả các plugin được liệt kê trong GeneratedPluginRegistrant.java
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }
}