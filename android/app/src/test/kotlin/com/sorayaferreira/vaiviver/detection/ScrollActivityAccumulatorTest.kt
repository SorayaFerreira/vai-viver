package com.sorayaferreira.vaiviver.detection

import org.junit.Assert.assertEquals
import org.junit.Test

class ScrollActivityAccumulatorTest {
    @Test
    fun `accumulates the gap between quick consecutive scroll events`() {
        var now = 0L
        val accumulator = ScrollActivityAccumulator(idleThresholdMs = 400L, clock = { now })

        accumulator.onScrollEvent()
        now = 200L
        accumulator.onScrollEvent()
        now = 500L
        accumulator.onScrollEvent()

        assertEquals(500L, accumulator.accumulatedMillis())
    }

    @Test
    fun `does not accumulate a gap larger than the idle threshold`() {
        var now = 0L
        val accumulator = ScrollActivityAccumulator(idleThresholdMs = 400L, clock = { now })

        accumulator.onScrollEvent()
        now = 2000L
        accumulator.onScrollEvent()

        assertEquals(0L, accumulator.accumulatedMillis())
    }

    @Test
    fun `reset clears the accumulated time`() {
        var now = 0L
        val accumulator = ScrollActivityAccumulator(idleThresholdMs = 400L, clock = { now })
        accumulator.onScrollEvent()
        now = 100L
        accumulator.onScrollEvent()

        accumulator.reset()

        assertEquals(0L, accumulator.accumulatedMillis())
    }
}
