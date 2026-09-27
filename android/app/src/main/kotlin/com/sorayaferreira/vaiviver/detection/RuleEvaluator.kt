package com.sorayaferreira.vaiviver.detection

fun evaluateRules(rules: List<DetectionRule>, root: ScreenNode, eventType: Int): RuleResult {
    for (rule in rules) {
        val result = rule.evaluate(root, eventType)
        if (result is RuleResult.Block) return result
    }
    return RuleResult.NoAction
}
