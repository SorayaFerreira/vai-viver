package com.sorayaferreira.vaiviver.detection

sealed class RuleResult {
    object NoAction : RuleResult()
    data class Block(val reason: BlockReason) : RuleResult()
}
