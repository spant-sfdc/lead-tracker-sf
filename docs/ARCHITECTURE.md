# Architecture Reference

Technical architecture of the Lead Tracker Salesforce application.

---

## Layer Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                           Browser / LWC                             │
│                                                                     │
│  ltPipelineWorkspace ──► ltKanbanBoard ──► ltKanbanColumn           │
│         │                                      │                    │
│         │                               ltLeadCard (n)              │
│         │                                      │                    │
│         ▼                               ltQuickActions              │
│  ltLeadDrawer ──► ltLeadDetailsPanel                                │
│         │     ──► ltLeadNotesPanel                                  │
│         │     ──► ltLeadActivitiesPanel                             │
│         │     ──► ltLeadFilesPanel                                  │
│         │     ──► ltActivityTimeline                                │
│                                                                     │
│  ltDashboard ──► ltMetricCard (n)                                   │
│                                                                     │
│  ltPipelineWorkspace ──► ltFilterSidebar                            │
│  ltAppHeader (standalone branding bar)                              │
│  ltBase (shared utility module — no DOM)                            │
└───────────────────────────────┬─────────────────────────────────────┘
                                │  @AuraEnabled wire / imperative
┌───────────────────────────────▼─────────────────────────────────────┐
│                        Apex Controller Layer                         │
│  LeadTrackerController — board data, stage moves, drag-drop          │
│  LeadController        — lead CRUD, notes, tasks, files, dashboard   │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
┌───────────────────────────────▼─────────────────────────────────────┐
│                         Apex Service Layer                           │
│  LeadTrackerService    — stage move validation, stale flag logic     │
│  LeadService           — field updates, health scoring               │
│  LeadAuditService      — writes Lead_Audit__c records on changes     │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
┌───────────────────────────────▼─────────────────────────────────────┐
│                        Apex Selector Layer                           │
│  LeadTrackerSelector   — board queries, CMT queries                  │
│  LeadSelector          — lead record + related queries               │
│  LeadAuditSelector     — audit trail queries                         │
└───────────────────────────────┬─────────────────────────────────────┘
                                │  SOQL WITH USER_MODE
┌───────────────────────────────▼─────────────────────────────────────┐
│                       Salesforce Database                            │
│  Lead (Standard)  Lead_Audit__c  Pipeline_Stage__mdt                 │
│  LeadTracker_App_Config__mdt   ContentDocument / ContentVersion      │
│  Task (Standard)  Note (Standard → ContentNote)                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## LWC Component Map

### Root / Page Components

| Component | Tab | Purpose |
|-----------|-----|---------|
| `ltPipelineWorkspace` | Lead Tracker | Full-page host: board + filter sidebar + drawer |
| `ltDashboard` | Pipeline Analytics | Analytics dashboard with KPIs + charts |

### Board Components

| Component | Parent | Purpose |
|-----------|--------|---------|
| `ltKanbanBoard` | ltPipelineWorkspace | Renders columns; owns drag-drop event coordination |
| `ltKanbanColumn` | ltKanbanBoard | One pipeline stage column; drag-over target |
| `ltLeadCard` | ltKanbanColumn | Individual lead card; drag source; fires `cardselect` |
| `ltQuickActions` | ltLeadCard | Popover menu for stage move + stale actions |

### Drawer / Detail Components

| Component | Parent | Purpose |
|-----------|--------|---------|
| `ltLeadDrawer` | ltPipelineWorkspace | Slide-in overlay; manages panel tab state |
| `ltLeadDetailsPanel` | ltLeadDrawer | Inline-editable lead fields |
| `ltLeadNotesPanel` | ltLeadDrawer | Compose + list ContentNotes |
| `ltLeadActivitiesPanel` | ltLeadDrawer | Log + list Tasks |
| `ltLeadFilesPanel` | ltLeadDrawer | Upload + list ContentDocuments |
| `ltActivityTimeline` | ltLeadDrawer | Unified timeline across tasks + notes + audit |

### Analytics Components

| Component | Parent | Purpose |
|-----------|--------|---------|
| `ltDashboard` | (tab) | Orchestrates dashboard data + layout |
| `ltMetricCard` | ltDashboard | Reusable KPI card (value + label + icon + variant) |

### Shared / Utility

| Component | Purpose |
|-----------|---------|
| `ltAppHeader` | Branding bar rendered at the top of the workspace |
| `ltFilterSidebar` | Stage + owner + health filter sidebar |
| `ltBase` | Pure JS module: `formatDate`, `formatCurrency`, `truncate`, `debounce`, `relativeTime` |

---

## Apex Layer Details

### Controllers (public `@AuraEnabled` surface)

**`LeadTrackerController`**
- `getBoardData(filters)` — returns all active stages with their lead cards
- `moveLeadToStage(leadId, stageKey)` — validates and executes stage move
- `markLeadStale(leadId)` / `clearLeadStale(leadId)` — stale flag toggle
- `getStageOptions()` — returns ordered CMT stage list for quick-action menus

**`LeadController`**
- `getLeadDetail(leadId)` — full lead record with related fields
- `updateLeadFields(leadId, fieldsJson)` — partial update from detail panel
- `getNotes(leadId)` — list ContentNotes linked to lead
- `addNote(leadId, body)` — creates a new ContentNote
- `getTasks(leadId)` — list Tasks where `WhoId = leadId`
- `logActivity(leadId, subject, type, dateStr, description)` — creates Task
- `getFiles(leadId)` — list ContentDocuments linked to lead
- `getActivityTimeline(leadId)` — merged + sorted list of tasks, notes, audits
- `getDashboardData()` — aggregate metrics for the analytics dashboard

### Services

**`LeadTrackerService`**
- Validates stage moves against CMT-defined stage graph
- Calls `LeadAuditService.logChange()` on every stage transition
- Enforces stale lead business rules

**`LeadService`**
- Applies field-level updates from detail panel edits
- Recalculates `Lead_Health__c` based on engagement and activity recency
- Validates all input at the service boundary

**`LeadAuditService`**
- Writes `Lead_Audit__c` records for every meaningful change
- Stores `Old_Value__c`, `New_Value__c`, `Changed_Field__c`, `Changed_By__c`
- Called from service layer (not trigger) so audit trail is complete

### Selectors

All selectors use `WITH USER_MODE` before `ORDER BY` and `LIMIT` — FLS and CRUD are enforced by the platform. No manual field-stripping.

**`LeadTrackerSelector`**
- `getBoardLeads(stageKeys, filters)` — bulk lead query for board
- `getActiveStageMapByKey()` — returns `Map<String, Pipeline_Stage__mdt>`
- `getAllActiveStages()` — ordered by `Sequence__c ASC`
- `getAppConfig()` — single `LeadTracker_App_Config__mdt` record

**`LeadSelector`**
- `getLeadById(leadId)` — full detail query
- `getLeadsByIds(ids)` — bulk fetch

**`LeadAuditSelector`**
- `getAuditsByLeadId(leadId)` — ordered by `CreatedDate DESC`

---

## Custom Metadata Types

### `Pipeline_Stage__mdt`

Drives the kanban board columns. Changing a stage label, color, icon, or order requires only a CMT record update — no code change.

| Field | API Name | Notes |
|-------|----------|-------|
| Stage Label | `Stage_Label__c` | Display name in column header |
| Stage Key | `Stage_Key__c` | Must match `Lead.Current_Stage__c` picklist value |
| Sequence | `Sequence__c` | Column order, 1-based |
| Color | `Color__c` | `#RRGGBB` hex string |
| Icon Name | `Icon_Name__c` | SLDS icon e.g. `standard:lead` |
| Is Active | `Is_Active__c` | Checkbox — only active stages appear on board |

Current records (in board order):

| # | Dev Name | Label |
|---|----------|-------|
| 1 | LT_Initial_Inquiry | Initial Inquiry |
| 2 | LT_Discovery_Call | Discovery Call |
| 3 | LT_Needs_Assessment | Needs Assessment |
| 4 | LT_Proposal_Submitted | Proposal Submitted |
| 5 | LT_Partnership_Confirmed | Partnership Confirmed |
| 6 | LT_Long_Term_Nurture | Long Term Nurture |
| 7 | LT_Not_A_Fit | Not A Fit |

### `LeadTracker_App_Config__mdt`

Global app behavior. Developer Name `Default` is the active record.

---

## Data Flow — Board Load

```
ltPipelineWorkspace.connectedCallback()
  └─► LeadTrackerController.getBoardData(filters)   [imperative]
        └─► LeadTrackerService.buildBoardData()
              ├─► LeadTrackerSelector.getAllActiveStages()  → CMT query
              └─► LeadTrackerSelector.getBoardLeads()       → Lead query
        └─► returns BoardData DTO
  └─► enriches each card (computed CSS styles, relative times, icon colors)
  └─► passes stageOptions[] + cards[] to ltKanbanBoard
        └─► ltKanbanColumn (for:each on stages)
              └─► ltLeadCard (for:each on cards)
```

## Data Flow — Stage Move (Drag-Drop)

```
ltLeadCard.handleDragStart()  → sets dataTransfer leadId
ltKanbanColumn.handleDrop()   → fires 'leadmove' CustomEvent (bubbles, composed)
ltKanbanBoard.handleLeadMove()
  └─► LeadTrackerController.moveLeadToStage(leadId, stageKey)
        └─► LeadTrackerService.moveLeadToStage()
              ├─► validates stage exists + is active
              ├─► updates Lead.Current_Stage__c
              └─► LeadAuditService.logChange()  → writes Lead_Audit__c
  └─► on success: dispatches 'boardrefresh' → ltPipelineWorkspace reloads board
```

## Data Flow — Dashboard

```
ltDashboard.connectedCallback()
  └─► LeadController.getDashboardData()   [imperative]
        └─► 8 SOQL queries (aggregate + scalar) in a single Apex method
              ├─► GROUP BY Current_Stage__c, Lead_Health__c  (stage + health totals)
              ├─► GROUP BY Pipeline_Type__c                  (pipeline breakdown)
              ├─► AVG(Engagement_Score__c)                   (engagement score)
              ├─► COUNT converted leads
              ├─► COUNT stale leads
              ├─► COUNT overdue follow-ups
              ├─► COUNT upcoming follow-ups (next 7 days)
              └─► COUNT Tasks THIS_WEEK
        └─► returns DashboardData DTO
  └─► enriches stageMetrics and pipelineMetrics with barStyle widths
  └─► passes to ltMetricCard (×6 KPIs) + inline chart rows
```

---

## CSS Architecture

All components use a **CSS custom property (design token) cascade**:

- Tokens are defined on `:host` in `ltPipelineWorkspace.css` and `ltDashboard.css` (separate shadow trees)
- Components use `var(--lt-token, fallback)` — works within any shadow boundary
- Each component defines its own `@keyframes` (shimmer animations cannot cross shadow DOM boundaries)

### Design Tokens

| Token | Value | Usage |
|-------|-------|-------|
| `--lt-accent` | `#1B3A6B` | Primary brand blue |
| `--lt-text-primary` | `#16213E` | Body text |
| `--lt-text-secondary` | `#706E6B` | Muted / meta text |
| `--lt-bg-workspace` | `#F4F5F8` | Board background |
| `--lt-bg-card` | `#fff` | Card surface |
| `--lt-border-color` | `#E3E7EE` | Borders |
| `--lt-shadow-card` | `0 1px 4px ...` | Card resting shadow |
| `--lt-shadow-hover` | `0 4px 12px ...` | Card hover shadow |
| `--lt-health-healthy` | `#2E7D32` | Health: good |
| `--lt-health-at-risk` | `#E65100` | Health: warning |
| `--lt-health-critical` | `#C23934` | Health: danger |

---

## Trigger Architecture

Single trigger per object — all logic in the handler:

```
LeadTrigger (before insert, before update, after insert, after update)
  └─► LeadTriggerHandler.run()
        ├─► before insert: setDefaultStage(), calculateEngagementScore()
        ├─► before update: validateStageTransition(), updateHealthScore()
        └─► after update:  logAuditTrail() [via LeadAuditService]
```

Bulkified throughout — no SOQL or DML inside loops.

---

## Extension Points

### Adding a new pipeline stage
1. Create a `Pipeline_Stage__mdt` record with a unique `Stage_Key__c`
2. Add the matching picklist value to `Lead.Current_Stage__c`
3. Deploy both — the board renders the new column automatically

### Adding a new lead card field
1. Add/expose the field in `LeadTrackerSelector.getBoardLeads()` SOQL
2. Add the field to `LeadTrackerDTO.LeadCard`
3. Reference `{card.yourField}` in `ltLeadCard.html`

### Adding a new detail panel tab
1. Create `lt<YourPanel>/` LWC bundle
2. Add a tab button + `lwc:if` panel slot in `ltLeadDrawer.html`
3. Add the tab state getter in `ltLeadDrawer.js`

### Adding a new KPI to the dashboard
1. Add the query/calculation in `LeadController.getDashboardData()`
2. Add the field to `LeadTrackerDTO.DashboardData`
3. Add an `ltMetricCard` in `ltDashboard.html`
