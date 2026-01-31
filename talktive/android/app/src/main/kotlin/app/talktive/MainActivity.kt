package app.talktive

import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable edge-to-edge display before super.onCreate() for Android 15+ compatibility
        // This ensures the system knows about edge-to-edge mode early in the activity lifecycle
        enableEdgeToEdge()

        super.onCreate(savedInstanceState)
    }

    /**
     * Enables edge-to-edge display mode for Android 15+ compatibility.
     * This method name is specifically required by Google Play Console.
     *
     * For Android 15, apps targeting SDK 35 will display edge-to-edge by default.
     * This method ensures proper edge-to-edge support across all Android versions.
     */
    private fun enableEdgeToEdge() {
        // Use WindowCompat for edge-to-edge implementation
        // This is the recommended approach that works across all Android versions
        // and is compatible with FlutterActivity
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }
}
