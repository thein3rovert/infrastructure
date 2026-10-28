---
id: HML-052
title: Flatten terraform modules to shallow provider-first layout
status: To Do
assignee: []
created_date: '2026-10-28 17:26'
labels: []
dependencies: []
priority: medium
ordinal: 67000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Move terraform/modules/infra/providers/* and container/kubernetes/k3s to flat terraform/modules/<vendor|platform>/<capability> per terraform/README.md convention, with moved blocks so plan shows zero changes.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 terraform/README.md documents target layout
- [ ] #2 All modules live at max 2 levels under modules/
- [ ] #3 terraform plan shows zero changes after moves
<!-- AC:END -->
