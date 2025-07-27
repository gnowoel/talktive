package app.talktive

import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable edge-to-edge display for Android 15+ compatibility
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }

    /**
     * Enables edge-to-edge display mode for Android 15+ compatibility.
     * This method name is specifically required by Google Play Console.
     */
    private fun enableEdgeToEdge() {
        // Use WindowCompat for edge-to-edge implementation
        // This is the recommended approach that works across all Android versions
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }
}
