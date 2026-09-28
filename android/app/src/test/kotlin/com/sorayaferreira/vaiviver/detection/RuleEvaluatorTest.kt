package com.sorayaferreira.vaiviver.detection

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

class RuleEvaluatorTest {
    @Test
    fun `returns the first blocking result and never calls later rules`() {
        val ruleA = object : DetectionRule {
            override fun evaluate(root: ScreenNode, eventType: Int) = RuleResult.Block(BlockReason.REELS_TAB)
        }
        val ruleB = object : DetectionRule {
            var called = false
            override fun evaluate(root: ScreenNode, eventType: Int): RuleResult {
                called = true
                return RuleResult.Block(BlockReason.FEED_TIME_LIMIT)
            }
        }

        val result = evaluateRules(listOf(ruleA, ruleB), ScreenNode(null, null, null), 0)

        assertEquals(RuleResult.Block(BlockReason.REELS_TAB), result)
        assertFalse(ruleB.called)
    }

    @Test
    fun `returns NoAction when no rule blocks`() {
        val rule = object : DetectionRule {
            override fun evaluate(root: ScreenNode, eventType: Int) = RuleResult.NoAction
        }

        assertEquals(RuleResult.NoAction, evaluateRules(listOf(rule), ScreenNode(null, null, null), 0))
    }
}
