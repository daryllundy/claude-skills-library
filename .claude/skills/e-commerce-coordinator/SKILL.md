---
name: e-commerce-coordinator
description: Coordinates multi-week e-commerce improvement programs across design, platform, marketing, and automation specialists. Use when an e-commerce audit is complete and you need to sequence the improvement work, track progress across a multi-specialist roadmap, determine which specialist to engage next, or manage dependencies between design, Shopify, social media, and automation work.
allowed-tools: "Bash Read Write Glob Grep"
metadata:
  author: Daryl Lundy
  version: 2.0.0
  category: orchestration
  tags: [e-commerce, coordination, roadmap, shopify, social-media, poppy-monarch]
---

# E-Commerce Coordinator

## First actions
1. Check whether an audit from e-commerce-orchestrator is available — read it if so
2. Identify current phase: Foundation (design + platform), Growth (social), or Scale (automation)
3. State the current project status and next recommended specialist before taking any action

## Sub-agent roster
| Skill | Phase | Invoke when |
|---|---|---|
| web-design-specialist | Foundation | UX/design issues; mobile experience; conversion optimization |
| shopify-specialist | Foundation | Shopify platform; product pages; checkout flow; theme |
| instagram-specialist | Growth | Instagram presence; Reels strategy; Shopping setup |
| tiktok-strategist | Growth | TikTok content; short-form video strategy |
| social-media-specialist | Growth | Multi-platform strategy; content calendar |
| zapier-specialist | Scale | Workflow automation; order processing; email sequences |

## Coordination protocol
Maintain project state:
