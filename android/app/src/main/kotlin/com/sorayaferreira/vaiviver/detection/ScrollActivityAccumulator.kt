package com.sorayaferreira.vaiviver.detection

class ScrollActivityAccumulator(
    private val idleThresholdMs: Long = 400L,
    private val clock: () -> Long = System::currentTimeMillis
) {
    private var lastEventAt: Long? = null
    private var accumulatedMs: Long = 0L

    fun onScrollEvent() {
        val now = clock()
        lastEventAt?.let { last ->
            val gap = now - last
            if (gap in 0..idleThresholdMs) {
                accumulatedMs += gap
            }
        }
        lastEventAt = now
    }

    fun accumulatedMillis(): Long = accumulatedMs

    fun reset() {
        accumulatedMs = 0L
        lastEventAt = null
    }
}
