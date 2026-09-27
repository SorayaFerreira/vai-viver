package com.sorayaferreira.vaiviver.detection

interface DetectionRule {
    fun evaluate(root: ScreenNode, eventType: Int): RuleResult
    fun onSessionEnded() {}
}
