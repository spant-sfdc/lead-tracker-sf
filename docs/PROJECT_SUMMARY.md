# Lead Tracker — Complete Project Summary

**Project:** TechPulse Lead Tracker
**Platform:** Salesforce (Lightning Web Components + Apex)
**API Version:** 66.0
**Org Alias:** `sf-dev-edition-partner-org`
**Repository:** https://github.com/spant-sfdc/lead-tracker-sf
**Total Phases Delivered:** 8

---

## What Was Built

A production-grade, enterprise Salesforce application that replaces manual pipeline management with a SaaS-like kanban board experience running entirely natively on Salesforce. Every aspect of the pipeline — stages, colors, icons, order, app config — is controlled through Custom Metadata Types with zero hardcoding anywhere in the codebase.

---

## Phase-by-Phase Breakdown

---

### Phase 1 — Foundation
**Commit:** `b9976ca`

Established the core project structure and Salesforce DX setup.

**What was built:**
- Salesforce DX project initialized with API v66.0, `sfdx-project.json` configured
- Org authentication (`sf-dev-edition-partner-org`, username `spant.38bdf20c3c08@agentforce.com`)
- Custom Metadata Type object definitions: `Pipeline_Stage__mdt`, `Application_Config__mdt`, `LeadTracker_Pipeline_Stage__mdt`, `LeadTracker_App_Config__mdt`
- Initial CMT records: 4 pipeline stages + app config Default record
- Service-layer Apex scaffold: `LeadTrackerException`, `LeadTrackerSelector`, `LeadTrackerService`, `LeadTrackerController`
- Single trigger pattern: `LeadTrigger` → `LeadTriggerHandler`
- LWC component scaffold: `ltBase`, `ltAppHeader`, `ltPipelineBoard`, `ltLeadCard`
- Console app definition: `LeadTracker.app-meta.xml`
- Custom labels for all UI strings
- Permission set: `Lead_Tracker_User`
- Git repository initialized with `.gitignore`, pushed to GitHub

---

### Phase 2 — Foundation Metadata Architecture
**Commit:** `f0d219f` (+ 6 fix commits)

Built out the full metadata schema and backend infrastructure.

**What was built:**

**Custom Fields on Lead (Standard Object):**
| Field | API Name | Purpose |
|-------|----------|---------|
| Current Stage | `Current_Stage__c` | Maps to pipeline board column |
| Pipeline Type | `Pipeline_Type__c` | Categorizes lead pipeline track |
| Last Activity Date | `Last_Activity_Date__c` | Tracks recency for health scoring |
| Next Follow-Up | `Next_Follow_Up__c` | Follow-up date for SLA tracking |
| Lead Health | `Lead_Health__c` | Computed: Healthy / At Risk / Critical |
| Engagement Score | `Engagement_Score__c` | Numeric engagement metric |
| Closed Reason | `Closed_Reason__c` | Why a lead was closed |
| Is Stale | `Is_Stale__c` | Boolean flag for stale leads |
| Primary Stakeholder | `Primary_Stakeholder__c` | Key contact at prospect |
| Organization Size | `Organization_Size__c` | Company size segment |
| Current CRM | `Current_CRM__c` | Lead's existing CRM system |
| Funding Model | `Funding_Model__c` | Revenue/funding classification |

**Custom Object — `Lead_Audit__c`:**
- AutoNumber name field: `LA-{000000}`
- Append-only audit trail — never updated, only inserted
- Fields: `Audit_Type__c`, `Performed_On__c`, `Performed_By__c`, `Old_Value__c`, `New_Value__c`, `Changed_Field__c`, `Message__c`
- Lookup to Lead with `deleteConstraint=SetNull` + `required=false` (preserves audit if Lead deleted)

**Pipeline Stage CMT records expanded:**
- `Pipeline_Stage__mdt` fields: `Stage_Key__c`, `Stage_Label__c`, `Sequence__c`, `Color__c`, `Icon__c`, `Is_Closed__c`, `Is_Won__c`, `Requires_Activity__c`, `SLA_Days__c`, `Pipeline_Type__c`, `Card_Badge_Config__c`

**`LeadAuditService`** — static builder/persist pattern for writing `Lead_Audit__c` records

**`LeadTriggerHandler`** — routed all Lead trigger events (before insert/update, after insert/update) through a handler class

**Key lessons from Phase 2:**
- `WITH USER_MODE` must appear before `ORDER BY` and `LIMIT` in SOQL
- Required fields (`Audit_Type__c`, `Performed_On__c`) must be OMITTED from PermissionSet `<fieldPermissions>` entirely
- `<userLicense>` is not valid in PermissionSet at API v66+
- Tab motif format: `Custom20: Coach` (legacy format, not namespace:icon)

---

### Phase 3 — Enterprise Apex Framework
**Commit:** `1fe3de5` + fix `510c598`

Complete enterprise-grade Apex architecture replacing the Phase 1 scaffold.

**What was built:**

**`TriggerHandler` (abstract base class)**
- Bypass/recursion guard via static Set
- Subclasses override `beforeInsert()`, `beforeUpdate()`, `afterInsert()`, `afterUpdate()` etc.
- `LeadTriggerHandler extends TriggerHandler` with actual business logic routing

**Selector Layer (read-only SOQL, all WITH USER_MODE):**
- `LeadSelector` — enterprise Lead queries: `getById()`, `getByIds()`, `getBoardLeads()` with filter support
- `PipelineStageSelector` — CMT queries: `getAllActiveStages()`, `getActiveStageMapByKey()`, `getAppConfig()`
- `LeadAuditSelector` — `getAuditsByLeadId()` ordered by `CreatedDate DESC`
- `LeadTrackerSelector` — backward-compatible wrapper

**Service Layer:**
- `LeadService` — `moveLeadToStage()`, `updateEngagementScore()`, `markLeadsStale()`, `computeHealth()`
- `PipelineService` — assembles `BoardData` DTO in 2 SOQL queries; badge computation; `getStageOptions()`
- `LeadAuditService` — refactored with static builder API + `getTimeline()` / `getRecentActivity()` returning typed DTOs
- `LeadTrackerService` — backward-compatible wrapper

**`LeadTrackerDTO` (all `@AuraEnabled` inner classes):**
- `BoardData` — top-level board response
- `StageColumn` — one kanban column (stageKey, stageLabel, color, leadCount, leads[])
- `LeadCard` — one card on the board (leadId, name, company, currentStage, leadHealth, engagementScore, isStale, etc.)
- `AppConfigData` — app branding config
- `AuditEntry` — timeline entry (auditType, message, oldValue, newValue, performedBy, performedOn)
- `MoveResult` — response from stage move
- `StageMoveRequest` — request to stage move
- `StageOption` — menu option for quick actions (stageKey, stageLabel, color)

**Controller Layer:**
- `LeadController` — thin `@AuraEnabled` surface; all exceptions wrapped as `AuraHandledException`
- `LeadTrackerController` — backward-compatible wrapper

**Test Suite** — full test coverage across all layers:
`LeadSelector_Test`, `PipelineStageSelector_Test` (implied by LeadTrackerSelector_Test), `LeadService_Test`, `LeadAuditService_Test`, `LeadController_Test`, `LeadTrackerController_Test`, `LeadTriggerHandler_Test`

---

### Phase 4 — Salesforce Console Application
**Commit:** `920da2b`

Built the Lightning Console app shell that hosts all future UI.

**What was built:**

**`LeadTracker.app-meta.xml` (Lightning Console):**
- Label: "TechPulse Lead Tracker"
- `navType=Console`, `uiType=Lightning`
- Brand color: `#1B3A6B` (navy), `shouldOverrideOrgTheme=true`
- Navigation tabs: Lead Tracker, Standard Lead, Standard Account, Standard Opportunity, Reports, Dashboards
- Workspace config: mappings for all 6 navigation items
- Utility bar: `LeadTracker_UtilityBar` FlexiPage

**`LeadTracker_UtilityBar` FlexiPage:**
- Template: `one:utilityBarTemplateDesktop`
- Utility items: History, Notes (`notes:utilityBarNoteList`), ToDo (`runtime_sales_todo_list:unifiedToDoListAuraWrapper`)

**Tabs:**
- `Lead_Tracker.tab-meta.xml` — LWC tab exposing `ltPipelineBoard`

**Key lessons from Phase 4:**
- This Developer Edition org has NO `AppPage` FlexiPage templates — only `UtilityBar` type FlexiPages work
- App references utility bar by FlexiPage DeveloperName string, not direct embedding
- `navType=Console` + `uiType=Lightning` is correct for console apps (NOT `uiType=LightningConsole`)

---

### Phase 5 — Kanban Workspace UI
**Commit:** `9297ae8`

Built the full pipeline board with drag-and-drop, filtering, and real-time interaction.

**What was built:**

**`ltPipelineWorkspace`** — root state owner for the entire board experience:
- Loads board data via `LeadTrackerController.getBoardData(filters)`
- Manages filter state (search, health, stale toggle, stage filter)
- Handles optimistic stage moves (card appears to move instantly before server confirms)
- Handles stale flag toggle
- Opens/closes the lead drawer
- Owns all `@track` state: stages, leads, filters, drawerLeadId, isLoading

**`ltFilterSidebar`** — left-side filter panel:
- Debounced search input (300ms)
- Health filter chips: All / Healthy / At Risk / Critical
- Stage filter pills (from CMT)
- Stale toggle
- Emits `filterchange` event to `ltPipelineWorkspace`

**`ltKanbanBoard`** — board renderer:
- Renders one `ltKanbanColumn` per active stage
- Passes `stageOptions` array down to each column (for quick actions)
- Coordinates `leadmove` events from columns
- Emits `boardrefresh` to workspace on successful move

**`ltKanbanColumn`** — individual stage column:
- Drag-over target with visual indicator (dashed border, tinted background)
- Drag counter pattern (prevents flicker when dragging over child elements)
- Drop hint animation while a lead is being dragged over
- Empty state (icon + message when no leads in column)
- Stage header: icon (from CMT), label, lead count badge
- Emits `leadmove` on drop, `leadselect` on card click

**`ltLeadCard`** — individual lead card:
- Draggable HTML5 drag source
- Health badge (colored pill: Healthy/At Risk/Critical)
- Company, name, engagement score display
- Stale indicator badge
- "More actions" button → opens `ltQuickActions` popover
- Click → opens `ltLeadDrawer`

**`ltQuickActions`** — popover action menu:
- "Move to Stage" section: shows all stages except current, each with colored dot
- "Mark as Stale" / "Clear Stale Flag" action
- Emits `quickaction` custom event (bubbles, composed) with `{ type, leadId, stageKey }`

**Key technical decisions:**
- Optimistic UI — board updates immediately on drag; rolls back on server error
- All stage metadata (labels, colors, icons, order) flows from CMT → Apex DTO → LWC `@api` props — never hardcoded
- CSS design tokens defined on `ltPipelineWorkspace :host`, cascade to all child shadow DOMs via `var(--lt-token, fallback)` pattern

---

### Phase 6 — Workspace Drawer + Timeline
**Commit:** `de289a6`

Built the full lead detail experience as a slide-in drawer with 5 tabbed panels.

**What was built:**

**`ltLeadDrawer`** — slide-in overlay panel:
- Animates in from the right (CSS transform + transition)
- 5 tabs: Timeline, Details, Activities, Notes, Files
- Close button + backdrop click to dismiss
- Emits `drawerclose` to `ltPipelineWorkspace`

**`ltActivityTimeline`** — unified chronological timeline:
- Merges Tasks, ContentNotes, and `Lead_Audit__c` records into a single sorted list
- Groups entries by date (Today, Yesterday, This Week, Earlier)
- Type-specific icons and colors per audit/activity type
- Shimmer skeleton loading state
- Empty state illustration

**`ltLeadDetailsPanel`** — inline-editable lead fields:
- `lightning-record-view-form` / `lightning-record-edit-form` for SLDS-native rendering
- 5 sections: Contact Info, Pipeline Info, Follow-Up, Qualification, Lead Info
- Covers all 12 custom Lead fields + standard fields (Name, Company, Email, Phone, Status)
- Edit / Save / Cancel workflow

**`ltLeadNotesPanel`** — notes panel:
- Textarea composer (focus-to-expand behavior)
- Submits via `LeadController.addNote(leadId, body)`
- Lists existing notes with title, relative time, author
- Shimmer skeleton + empty state
- Toast on success/error (Phase 8)

**`ltLeadActivitiesPanel`** — activity logger:
- Collapsible `<details>` form (Log Activity toggle)
- Fields: Subject (required), Type (Call/Email/Meeting/Other), Date, Notes
- Submits via `LeadController.logActivity(...)`
- Lists existing Tasks with type icon, subject, description, relative time, owner
- Shimmer skeleton + empty state
- Toast on success/error (Phase 8)

**`ltLeadFilesPanel`** — file attachments:
- `lightning-file-upload` component (Salesforce native, handles ContentDocument creation)
- Lists attached files with file-type icon (color-coded by extension: PDF red, Word blue, Excel green, etc.)
- Shows file size, relative upload time, uploader name
- Download link for each file
- Shimmer skeleton + empty state

---

### Phase 7 — Pipeline Analytics Dashboard
**Commit:** `d38cbae`

Built a lightweight analytics dashboard as a second console tab.

**What was built:**

**`LeadTrackerDTO` additions** — 3 new inner DTO classes:
- `DashboardData` — top-level response with all KPI fields
- `StageMetric` — per-stage breakdown (stageKey, label, color, count, percentage)
- `PipelineMetric` — per-pipeline-type breakdown (pipelineType, count, percentage)

**`LeadController.getDashboardData()`** — 8 SOQL queries in a single `@AuraEnabled` call:
| Query | What it measures |
|-------|-----------------|
| `GROUP BY Current_Stage__c, Lead_Health__c` | Stage-level counts + health totals in one aggregate |
| `GROUP BY Pipeline_Type__c` | Pipeline breakdown |
| `AVG(Engagement_Score__c)` | Average engagement across all open leads |
| `COUNT WHERE IsConverted=true` | Total conversions |
| `COUNT WHERE Is_Stale__c=true` | Stale leads |
| `COUNT WHERE Next_Follow_Up__c < TODAY` | Overdue follow-ups |
| `COUNT WHERE Next_Follow_Up__c = NEXT_N_DAYS:7` | Upcoming follow-ups |
| `COUNT Tasks WHERE ActivityDate = THIS_WEEK` | Activities logged this week |

**`ltDashboard`** — full analytics page (exposed as "Pipeline Analytics" console tab):
- App header + page header with manual refresh button
- **KPI grid (6 cards):** Total Leads, Open Leads, Conversion Rate, Avg Engagement, Overdue Follow-Ups, Activities This Week
- **Stage Funnel:** CSS-only horizontal bar chart; each bar width = `(count/total)*100%`, colored per CMT color
- **Health Breakdown:** 3 bars (Healthy/At Risk/Critical) with health-token colors
- **Pipeline Distribution:** Per-pipeline-type breakdown bars
- **Follow-Up / Engagement panel:** 2×2 stat grid + engagement score color-coded progress track
- "Last refreshed at HH:MM:SS" indicator

**`ltMetricCard`** — reusable KPI card component:
- `@api` props: `value`, `label`, `icon`, `sublabel`, `variant`
- `variant` drives color accent (default, warning, danger, success)
- Icon-wrap with tinted background per variant

**`Lead_Tracker_Dashboard` tab** — second tab in the console app:
- `CustomTab` with `lwcComponent=ltDashboard`
- Added to `LeadTracker.app-meta.xml` navigation (second position)

---

### Phase 8 — UX Polish + Production Finalization
**Commit:** `2b40d5d`

Production-quality polish pass across the entire application.

**What was built:**

#### 1. Shimmer Skeleton Loaders
Every loading state replaced with a pixel-accurate shimmer animation that mirrors the actual content layout:

| Component | Skeleton shape |
|-----------|---------------|
| `ltPipelineWorkspace` | 4 column skeletons (272px each) with header + 4–5 card blocks per column |
| `ltDashboard` | 6 KPI card blocks + 4 chart-row blocks |
| `ltLeadNotesPanel` | 3 card items (title line + 1–2 body lines) |
| `ltLeadActivitiesPanel` | 3 items (circle icon + title + line) |
| `ltLeadFilesPanel` | 3 items (36px icon square + name + meta lines) |

Each component defines its own `@keyframes <name>Shimmer` animation (LWC shadow DOM isolation prevents sharing keyframes across components).

#### 2. Toast Notifications
| Action | Toast |
|--------|-------|
| Note saved successfully | "Note Saved" — success |
| Note save failed | Error message from server — error |
| Activity logged | "Activity Logged — {subject} recorded successfully." — success |
| Activity log failed | Error message from server — error |

#### 3. Keyboard Accessibility
| Element | Keys supported |
|---------|---------------|
| Lead cards (`ltLeadCard`) | `Enter` / `Space` → open drawer; `Escape` → close quick actions popover |
| Quick action menu items (`ltQuickActions`) | `Enter` / `Space` → trigger action; `Escape` → close menu |
| Lead drawer (`ltLeadDrawer`) | `Escape` anywhere inside drawer → close drawer |

All focusable elements use `:focus-visible` (keyboard-only focus ring — not shown on mouse click).

**ARIA additions:**
- `tabindex="0"` on lead card `<article>` elements
- `aria-label={cardAriaLabel}` — computed as "{Name} at {Company}"
- `aria-expanded={showActions}` on action button
- `aria-haspopup="menu"` on action button
- `role="menu"` on quick actions panel, `role="menuitem"` on all items

#### 4. Focus Management
- `ltLeadDrawer`: auto-focuses the close button when the drawer opens (`renderedCallback` + `_panelFocused` guard)
- Document-level `keydown` listener for Escape (so it works regardless of focus position inside the drawer)
- Listener cleaned up in `disconnectedCallback` to prevent memory leaks

#### 5. Entrance Animations
| Component | Animation |
|-----------|-----------|
| `ltLeadCard` | `lcEnter`: `opacity 0→1` + `translateY(6px→0)` over 0.18s ease |
| `ltKanbanColumn` | `colEnter`: `opacity 0→1` + `translateY(8px→0)` over 0.25s `cubic-bezier(0.22, 1, 0.36, 1)` |

Stagger effect on board load happens naturally since LWC mounts components sequentially.

#### 6. `relativeTime` Utility Centralized
The `_relativeTime()` private method was duplicated in 4 components (`ltActivityTimeline`, `ltLeadNotesPanel`, `ltLeadActivitiesPanel`, `ltLeadFilesPanel`). Extracted into `ltBase.js` as `export const relativeTime`:
```
< 1 min   → "just now"
< 60 min  → "Xm ago"
< 24 hrs  → "Xh ago"
< 7 days  → "Xd ago"
≥ 7 days  → formatted date
```

#### 7. Documentation
- `README.md` — rewritten to reflect full production feature set, quick-start, project structure, naming conventions
- `docs/DEPLOYMENT.md` — step-by-step deployment guide: auth, full deploy, targeted deploy, tests, permission set, CMT verification, scratch org setup, deployment order for new orgs, troubleshooting table
- `docs/ARCHITECTURE.md` — component map, data flow diagrams for board load / stage move / dashboard, Apex layer details, CSS token table, trigger architecture, extension points

---

## Complete File Inventory

### Apex Classes (14 production classes + 9 test classes)

| Class | Layer | Purpose |
|-------|-------|---------|
| `TriggerHandler` | Framework | Abstract base with bypass/recursion guard |
| `LeadTrackerException` | Framework | Typed exception for all layers |
| `LeadTrackerDTO` | DTO | All `@AuraEnabled` inner classes |
| `LeadSelector` | Selector | Enterprise Lead SOQL queries |
| `PipelineStageSelector` | Selector | CMT queries for stages and app config |
| `LeadAuditSelector` | Selector | `Lead_Audit__c` queries |
| `LeadTrackerSelector` | Selector | Board queries (wraps LeadSelector) |
| `LeadService` | Service | Stage moves, health scoring, stale logic |
| `PipelineService` | Service | Board data assembly, DTO building |
| `LeadAuditService` | Service | Writes audit trail, builds timeline DTOs |
| `LeadTrackerService` | Service | Stage validation wrapper |
| `LeadController` | Controller | Lead CRUD, notes, tasks, files, dashboard |
| `LeadTrackerController` | Controller | Board operations, stage moves |
| `LeadTriggerHandler` | Trigger | Routes all Lead trigger events |

### LWC Components (18 components)

| Component | Category | Purpose |
|-----------|----------|---------|
| `ltBase` | Utility | Shared JS utilities (no DOM) |
| `ltAppHeader` | Chrome | Branded top bar |
| `ltPipelineBoard` | Page | Tab-exposed wrapper for workspace |
| `ltPipelineWorkspace` | Page | Root state owner: board + filters + drawer |
| `ltFilterSidebar` | Board | Search, health chips, stale toggle |
| `ltKanbanBoard` | Board | Renders stage columns |
| `ltKanbanColumn` | Board | One stage column; drag target |
| `ltLeadCard` | Board | Draggable lead card |
| `ltQuickActions` | Board | Popover action menu |
| `ltLeadDrawer` | Drawer | Slide-in detail overlay |
| `ltActivityTimeline` | Drawer | Unified timeline of all lead activity |
| `ltLeadDetailsPanel` | Drawer | Inline-editable lead fields |
| `ltLeadNotesPanel` | Drawer | Note composer + list |
| `ltLeadActivitiesPanel` | Drawer | Activity logger + task list |
| `ltLeadFilesPanel` | Drawer | File upload + attachment list |
| `ltDashboard` | Analytics | Pipeline analytics page |
| `ltMetricCard` | Analytics | Reusable KPI card |
| `ltPipelineBoard` | Legacy | Thin tab wrapper |

### Custom Metadata Types (4 CMT types, 11 records)

| Type | Records | Purpose |
|------|---------|---------|
| `Pipeline_Stage__mdt` | 7 | Board columns (Initial Inquiry → Not A Fit) |
| `Application_Config__mdt` | 1 | App-wide behavior config |
| `LeadTracker_Pipeline_Stage__mdt` | 2 | Legacy stage references |
| `LeadTracker_App_Config__mdt` | 1 | Legacy app config |

### Other Metadata

| Type | Item | Purpose |
|------|------|---------|
| Custom Object | `Lead_Audit__c` | Append-only audit trail |
| Custom Fields | 12 on `Lead` | Current_Stage, Health, Engagement, etc. |
| Apex Trigger | `LeadTrigger` | Single trigger, all Lead events |
| Custom App | `LeadTracker` | TechPulse Lead Tracker console |
| Custom Tabs | `Lead_Tracker`, `Lead_Tracker_Dashboard` | Board and analytics tabs |
| FlexiPage | `LeadTracker_UtilityBar` | Utility bar (History, Notes, ToDo) |
| Permission Set | `Lead_Tracker_User` | All Lead Tracker access |
| Custom Labels | ~20 | All UI strings |

---

## Architecture Principles

| Principle | How it's implemented |
|-----------|---------------------|
| **Metadata-driven** | All pipeline stages, colors, icons, order come from CMT records — change a stage by editing a record, not code |
| **Selector → Service → Controller** | Strict layering: no SOQL in service/controller, no business logic in selectors |
| **One trigger per object** | `LeadTrigger` routes all events through `LeadTriggerHandler extends TriggerHandler` |
| **No SOQL in loops** | All queries return collections; processing is done over in-memory collections |
| **WITH USER_MODE** | All SOQL enforces FLS and CRUD at the database level — no manual field stripping |
| **Zero hardcoding** | No hardcoded stage names, colors, icons, org IDs, or User IDs anywhere |
| **CSS design tokens** | `--lt-*` custom properties defined in workspace/dashboard root, cascade to all child shadow DOMs |
| **Shadow DOM isolation respected** | Each component owns its own `@keyframes`; no cross-shadow style sharing |
| **Optimistic UI** | Board updates immediately on drag; server confirms async; rolls back on error |
| **Append-only audit trail** | `Lead_Audit__c` records are never updated or deleted; preserves history even if Lead is deleted |

---

## Design System

All components share a consistent design language via CSS custom properties:

| Token | Value | Usage |
|-------|-------|-------|
| `--lt-accent` | `#1B3A6B` | Primary navy blue |
| `--lt-text-primary` | `#16213E` | Body text, headings |
| `--lt-text-secondary` | `#706E6B` | Meta text, labels |
| `--lt-bg-workspace` | `#F4F5F8` | Board / panel background |
| `--lt-bg-card` | `#FFFFFF` | Card surfaces |
| `--lt-border-color` | `#E3E7EE` | All borders and dividers |
| `--lt-health-healthy` | `#2E7D32` | Green — Healthy leads |
| `--lt-health-at-risk` | `#E65100` | Orange — At Risk leads |
| `--lt-health-critical` | `#C23934` | Red — Critical leads |

---

## Git Commit History

| Commit | Phase | Description |
|--------|-------|-------------|
| `b9976ca` | Phase 1 | Initialize Lead Tracker foundational architecture |
| `f0d219f` | Phase 2 | Foundation metadata architecture |
| `1fe3de5` | Phase 3 | Enterprise Apex Framework |
| `510c598` | Phase 3 fix | Static method calls, Pipeline_Stage__mdt field fix |
| `920da2b` | Phase 4 | Salesforce Console Application |
| `9297ae8` | Phase 5 | Kanban Workspace UI — metadata-driven drag-and-drop |
| `de289a6` | Phase 6 | Workspace Drawer + Timeline |
| `d38cbae` | Phase 7 | Analytics Dashboard — pipeline metrics and health insights |
| `2b40d5d` | Phase 8 | UX polish + production finalization |

---

## Deployment

```bash
# Full deploy
sf project deploy start \
  --source-dir force-app \
  --target-org sf-dev-edition-partner-org \
  --wait 15

# Assign permission set
sf org assign permset \
  --name Lead_Tracker_User \
  --target-org sf-dev-edition-partner-org

# Run tests
sf apex run test \
  --target-org sf-dev-edition-partner-org \
  --code-coverage --result-format human --wait 15

# Open org
sf org open --target-org sf-dev-edition-partner-org
```

See [DEPLOYMENT.md](DEPLOYMENT.md) for the full guide and troubleshooting.

---

## What the App Looks Like

### Tab 1: Lead Tracker (Pipeline Board)
```
┌─────────────────────────────────────────────────────────────────────────┐
│  TechPulse Lead Tracker                              [Refresh] [Filter] │
├──────────┬──────────────┬──────────────┬──────────────┬─────────────────┤
│ INITIAL  │  DISCOVERY   │   NEEDS      │  PROPOSAL    │  PARTNERSHIP    │
│ INQUIRY  │    CALL      │ ASSESSMENT   │  SUBMITTED   │  CONFIRMED      │
│   (12)   │     (8)      │    (6)       │     (4)      │      (3)        │
├──────────┼──────────────┼──────────────┼──────────────┼─────────────────┤
│ ┌──────┐ │ ┌──────────┐ │ ┌──────────┐ │              │                 │
│ │ Lead │ │ │  Lead    │ │ │  Lead    │ │  [drag here] │  [drag here]    │
│ │ Card │ │ │  Card    │ │ │  Card    │ │              │                 │
│ └──────┘ │ └──────────┘ │ └──────────┘ │              │                 │
│ ...      │ ...          │ ...          │              │                 │
└──────────┴──────────────┴──────────────┴──────────────┴─────────────────┘
                                                        ┌─────────────────┐
                                                        │  Lead Drawer    │
                                                        │  [Timeline]     │
                                                        │  [Details]      │
                                                        │  [Activities]   │
                                                        │  [Notes]        │
                                                        │  [Files]        │
                                                        └─────────────────┘
```

### Tab 2: Pipeline Analytics
```
┌─────────────────────────────────────────────────────────────────────────┐
│  Pipeline Analytics                                          [Refresh]  │
├──────────────────────────────────────────────────────────────────────── │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────┐ ┌──────┐│
│  │ 47       │ │ 38       │ │ 21.3%    │ │ 72.4     │ │  5   │ │  12  ││
│  │Total     │ │ Open     │ │Conversion│ │Engagement│ │Overdue│ │ This ││
│  │Leads     │ │ Leads    │ │  Rate    │ │  Score   │ │Follow │ │ Week ││
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────┘ └──────┘│
│                                                                          │
│  Stage Funnel                    │  Lead Health                         │
│  Initial Inquiry  ████████ 12   │  Healthy  ████████████████ 24        │
│  Discovery Call   ██████   8    │  At Risk  ███████          10        │
│  Needs Assessment █████    6    │  Critical ████              4        │
│                                                                          │
│  Pipeline Distribution           │  Engagement + Follow-Ups             │
│  Enterprise      ████████ 18    │  Score: 72.4  ████████░░░░           │
│  SMB             █████    12    │  Overdue: 5  │ Upcoming: 8           │
└─────────────────────────────────────────────────────────────────────────┘
```

---

*Lead Tracker — Built with enterprise standards for extensibility, maintainability, and AppExchange-readiness.*
*Last updated: Phase 8 complete | Deployed: 2026-05-26*
