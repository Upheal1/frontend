package com.example.flutter_my_app_main

import android.accessibilityservice.AccessibilityService
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.graphics.Bitmap
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Display
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.Toast
import androidx.core.app.NotificationCompat

private const val TAG = "AppBlockAccessibilityService"
private const val ACTION_BLOCK_EVENT = "com.example.flutter_my_app_main.BLOCK_EVENT"
private const val EXTRA_BLOCKED_PACKAGE = "blocked_package"
private const val EXTRA_BLOCK_REASON = "block_reason"
private const val BLOCK_REASON_LIMIT_EXCEEDED = "limit_exceeded"
private const val CHANNEL_ID = "app_block_channel"

class AppBlockAccessibilityService : AccessibilityService() {

    // ==========================================
    // === Instant Threat Detection (Dictionary) ==
    // ==========================================
    private val badWords = listOf(
        "stupid", "idiot", "hate", "ugly", "fuck", "shit",
        "غبي", "حمار", "اكرهك", "قبيح", "زفت"
    )

    private val temporaryBlocks = mutableMapOf<String, Long>()
    private val blockDurationMs = 60 * 1000L // حظر لمدة دقيقة

    // ==========================================
    // === 👁️ متغيرات عين الصقر (NSFW Vision) ===
    // ==========================================
    private var visionClassifier: EdgeAIVisionClassifier? = null
    private val visionHandler = Handler(Looper.getMainLooper())

    // تصحيح: استخدام دالة run بدلاً من invoke لتعريف الـ Runnable
    private val visionRunnable = object : Runnable {
        override fun run() {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                captureAndAnalyzeScreen()
            }
            visionHandler.postDelayed(this, 4000) // تكرار الفحص كل 4 ثواني
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "UpHeal Ultimate Shield Connected (Anti-Tamper & Vision Active)")
        createNotificationChannel()

        // تهيئة مصنف الصور وتشغيل عين الصقر
        visionClassifier = EdgeAIVisionClassifier(this)
        visionHandler.postDelayed(visionRunnable, 4000)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "App Blocking Notifications",
                NotificationManager.IMPORTANCE_HIGH
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        val rootNode = rootInActiveWindow
        val packageName = rootNode?.packageName?.toString() ?: event.packageName?.toString() ?: return

        // 🚨 حماية النظام: استثناء الكيبورد وواجهة النظام من الحظر
        if (packageName.contains("inputmethod") ||
            packageName.contains("systemui") ||
            packageName.contains("launcher") ||
            packageName == applicationContext.packageName) {
            rootNode?.recycle()
            return
        }

        // --- 1. التحقق من العقوبة المؤقتة (منع فتح التطبيق المعاقب) ---
        if (isTemporarilyBlocked(packageName)) {
            performGlobalAction(GLOBAL_ACTION_HOME)
            showToast("🛑 هذا التطبيق محظور مؤقتاً!")
            rootNode?.recycle()
            return
        }

        // --- 2. سحب النص الشامل من الشاشة الحالية ---
        val eventText = event.text?.joinToString(" ")?.lowercase() ?: ""
        val screenText = getAllTextFromNode(rootNode).lowercase()
        val fullText = "$eventText $screenText"

        // --- 3. 🛡️ حقل الألغام (Ultimate Anti-Tampering) ---
        // منع المستخدم من إيقاف أو مسح التطبيق من الإعدادات
        if (packageName == "com.android.settings" || packageName == "com.miui.securitycenter") {
            if (fullText.contains("upheal") || fullText.contains("flutter_my_app_main")) {
                val dangerousKeywords = listOf("force stop", "uninstall", "clear data", "إيقاف إجباري", "إزالة", "مسح البيانات", "إلغاء التثبيت")
                for (keyword in dangerousKeywords) {
                    if (fullText.contains(keyword)) {
                        Log.w(TAG, "🚨 Anti-Tampering Triggered!")
                        performGlobalAction(GLOBAL_ACTION_HOME)
                        showToast("🛑 محاولة اختراق مرفوضة! لا يمكن إيقاف الحماية.")
                        triggerAppBlockWarning("com.android.settings", "محاولة مسح التطبيق أو إيقافه")
                        rootNode?.recycle()
                        return
                    }
                }
            }
        }

        // --- 4. منطق حظر التطبيقات العادي (المجدول أو اليدوي) ---
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            handleAppBlocking(packageName)
        }

        // --- 5. قناص الكلمات المسيئة ---
        if (fullText.isNotBlank()) {
            checkForBadWords(fullText, packageName)
        }

        rootNode?.recycle()
    }

    // ==========================================
    // === 👁️ تحليل الشاشة (عين الصقر) ===
    // ==========================================
    private fun captureAndAnalyzeScreen() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                takeScreenshot(Display.DEFAULT_DISPLAY, applicationContext.mainExecutor, object : TakeScreenshotCallback {
                    override fun onSuccess(screenshot: ScreenshotResult) {
                        try {
                            val hardwareBuffer = screenshot.hardwareBuffer
                            val bitmap = Bitmap.wrapHardwareBuffer(hardwareBuffer, screenshot.colorSpace)

                            val isNsfw = visionClassifier?.analyzeImage(bitmap!!) ?: false
                            if (isNsfw) {
                                Log.e("EdgeAIVision", "🚨 NSFW Detected!")
                                performGlobalAction(GLOBAL_ACTION_HOME)
                                triggerAppBlockWarning("NSFW_IMAGE_DETECTED", "تم اكتشاف محتوى غير لائق")
                            }

                            bitmap?.recycle()
                            hardwareBuffer.close()
                        } catch (e: Exception) {
                            Log.e(TAG, "Error processing screenshot: ${e.message}")
                        }
                    }
                    override fun onFailure(errorCode: Int) {
                        Log.e(TAG, "Screenshot failed: $errorCode")
                    }
                })
            } catch (e: SecurityException) {
                Log.e(TAG, "Screenshot not permitted: ${e.message}")
            }
        }
    }

    // ==========================================
    // === 🕷️ سحب النصوص الشامل (Root Scanner) ===
    // ==========================================
    private fun getAllTextFromNode(node: AccessibilityNodeInfo?): String {
        if (node == null) return ""
        val sb = StringBuilder()

        if (node.text != null) sb.append(node.text).append(" ")
        if (node.contentDescription != null) sb.append(node.contentDescription).append(" ")

        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            if (child != null) {
                sb.append(getAllTextFromNode(child))
                child.recycle()
            }
        }
        return sb.toString()
    }

    // ==========================================
    // === منطق العقوبات والتحذيرات ===
    // ==========================================
    private fun checkForBadWords(text: String, packageName: String) {
        for (word in badWords) {
            if (text.contains(word)) {
                Log.d(TAG, "🚨 Bad word: '$word' in $packageName")
                triggerAppBlockWarning(packageName, "استخدام ألفاظ غير لائقة")
                return
            }
        }
    }

    private fun triggerAppBlockWarning(packageName: String, reason: String) {
        temporaryBlocks[packageName] = System.currentTimeMillis() + blockDurationMs
        performGlobalAction(GLOBAL_ACTION_HOME)
        showToast("⚠️ $reason! تم حظر التطبيق.")

        // إرسال Broadcast إلى Flutter
        val intent = Intent("com.example.flutter_my_app_main.THREAT_DETECTED").apply {
            putExtra("confidence_score", 1.0f)
            putExtra("blocked_package", packageName)
            setPackage(applicationContext.packageName)
            addFlags(Intent.FLAG_INCLUDE_STOPPED_PACKAGES)
        }
        sendBroadcast(intent)

        // فتح تطبيقنا لإظهار شاشة التحذير
        val launchIntent = packageManager.getLaunchIntentForPackage(applicationContext.packageName)
        launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        startActivity(launchIntent)
    }

    private fun isTemporarilyBlocked(packageName: String): Boolean {
        val unblockTime = temporaryBlocks[packageName] ?: return false
        if (System.currentTimeMillis() < unblockTime) return true
        temporaryBlocks.remove(packageName)
        return false
    }

    private fun showToast(message: String) {
        Handler(Looper.getMainLooper()).post {
            Toast.makeText(applicationContext, message, Toast.LENGTH_LONG).show()
        }
    }

    private fun handleAppBlocking(packageName: String) {
        try {
            val database = AppBlockDatabase(this)
            if (database.isAppBlocked(packageName)) {
                val appInfo = packageManager.getApplicationInfo(packageName, 0)
                val appName = packageManager.getApplicationLabel(appInfo).toString()

                val notification = NotificationCompat.Builder(this, CHANNEL_ID)
                    .setContentTitle("App Blocked")
                    .setContentText("تم حظر $appName.")
                    .setSmallIcon(android.R.drawable.ic_lock_lock)
                    .setAutoCancel(true)
                    .build()

                getSystemService(NotificationManager::class.java)?.notify(packageName.hashCode(), notification)

                val intent = Intent(this, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra("blocked_package", packageName)
                    putExtra("blocked_reason", BLOCK_REASON_LIMIT_EXCEEDED)
                }
                startActivity(intent)

                Handler(Looper.getMainLooper()).postDelayed({
                    val broadcast = Intent(ACTION_BLOCK_EVENT).apply {
                        setPackage("com.example.flutter_my_app_main")
                        putExtra(EXTRA_BLOCKED_PACKAGE, packageName)
                        putExtra(EXTRA_BLOCK_REASON, BLOCK_REASON_LIMIT_EXCEEDED)
                    }
                    sendBroadcast(broadcast)
                }, 300)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in handleAppBlocking: ${e.message}")
        }
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        super.onDestroy()
        visionClassifier?.close()
        visionHandler.removeCallbacks(visionRunnable)
    }
}