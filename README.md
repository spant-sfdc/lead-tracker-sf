# Lead Tracker

A modern, production-grade Salesforce pipeline management app built natively on the Salesforce Platform. Features a metadata-driven kanban board, full lead detail drawer, inline activities/notes/files, and a live analytics dashboard — all built with Lightning Web Components and a clean service-layer Apex architecture.

---

## Features

| Feature | Description |
|---------|-------------|
| **Kanban Pipeline Board** | Drag-and-drop lead management across configurable pipeline stages |
| **Metadata-Driven Stages** | Every stage (label, color, icon, order) is a Custom Metadata record — zero hardcoding |
| **Lead Detail Drawer** | Slide-in panel with inline editable fields, health score, and engagement tracking |
| **Activity Log** | Log calls, emails, meetings, and other interactions directly from the board |
| **Notes Panel** | Freeform notes attached to each lead |
| **Files Panel** | Upload and download lead attachments (Salesforce ContentDocument) |
| **Activity Timeline** | Unified timeline view across tasks, notes, and lead history |
| **Pipeline Analytics Dashboard** | KPI cards, stage funnel, health breakdown, engagement score, follow-up indicators |
| **Shimmer Skeleton Loaders** | Native loading states for all panels and the board |
| **Toast Notifications** | Success and error toasts on all user actions |
| **Keyboard Accessibility** | Enter/Space/Escape on all interactive elements; focus management; `:focus-visible` rings |
| **Entrance Animations** | Smooth card and column mount animations |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                          LWC UI Layer                           │
│  ltPipelineWorkspace  ltKanbanBoard  ltKanbanColumn  ltLeadCard  │
│  ltLeadDrawer  ltLeadDetailsPanel  ltLeadNotesPanel             │
│  ltLeadActivitiesPanel  ltLeadFilesPanel  ltActivityTimeline     │
│  ltDashboard  ltMetricCard  ltFilterSidebar  ltQuickActions      │
│  ltAppHeader  ltBase (shared utilities)                          │
└──────────────────────────────┬──────────────────────────────────┘
                               │  @AuraEnabled
┌──────────────────────────────▼──────────────────────────────────┐
│                       Controller Layer                           │
│         LeadController  LeadTrackerController                    │
│         LeadAuditService  LeadSelector                           │
└──────────────────────────────┬──────────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────────┐
│                        Service Layer                             │
│         LeadTrackerService  LeadService  LeadAuditService        │
└──────────────────────────────┬──────────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────────┐
│                       Selector Layer                             │
│         LeadTrackerSelector  LeadSelector  LeadAuditSelector     │
└──────────────────────────────┬──────────────────────────────────┘
                               │  SOQL WITH USER_MODE
┌──────────────────────────────▼──────────────────────────────────┐
│                     Salesforce Platform                          │
│   Lead (Standard)  Lead_Audit__c (Custom)  CMT Types             │
└─────────────────────────────────────────────────────────────────┘
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for a full component map and data flow.

---

## Quick Start

### Prerequisites

- Salesforce CLI (`sf`) v2.x+
- Node.js 18+
- An authorized Salesforce org

### Deploy

```bash
# Verify auth
sf org display --target-org sf-dev-edition-partner-org

# Deploy all metadata
sf project deploy start \
  --source-dir force-app \
  --target-org sf-dev-edition-partner-org \
  --wait 15

# Assign permission set
sf org assign permset \
  --name Lead_Tracker_User \
  --target-org sf-dev-edition-partner-org

# Open org
sf org open --target-org sf-dev-edition-partner-org
```

See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for the full step-by-step guide.

---

## Custom Metadata Types

### `Pipeline_Stage__mdt` — Pipeline board columns

| Field | Type | Purpose |
|-------|------|---------|
| `Stage_Label__c` | Text | Display name for the column header |
| `Stage_Key__c` | Text | Maps to `Lead.Current_Stage__c` picklist value |
| `Sequence__c` | Number | Column left-to-right order |
| `Color__c` | Text(7) | Accent color in `#RRGGBB` format |
| `Icon_Name__c` | Text | SLDS icon name (e.g. `standard:lead`) |
| `Is_Active__c` | Checkbox | Enables/disables this column |

### `LeadTracker_App_Config__mdt` — App-wide config

| Field | Type | Purpose |
|-------|------|---------|
| `App_Name__c` | Text | Application display name |
| `Primary_Color__c` | Text(7) | Brand primary color |
| `Support_Email__c` | Email | Support contact |

### Adding a Stage

Create a new CMT record — no code changes required:

```bash
# Via Salesforce Setup > Custom Metadata Types > Pipeline Stage > Manage Records
# Or deploy a new .md-meta.xml file:
sf project deploy start \
  --metadata "CustomMetadata:Pipeline_Stage.LT_Your_Stage" \
  --target-org sf-dev-edition-partner-org
```

---

## Project Structure

```
lead-tracker-sf/
├── docs/
│   ├── ARCHITECTURE.md          # Component map, data flow, extension points
│   └── DEPLOYMENT.md            # Step-by-step deployment guide
├── force-app/main/default/
│   ├── applications/            # LeadTracker console app definition
│   ├── classes/                 # Apex — Selector / Service / Controller / Handler
│   ├── customMetadata/          # Pipeline stages + app config CMT records
│   ├── lwc/                     # All Lightning Web Components (prefix: lt)
│   ├── objects/                 # CMT type + field definitions, Lead fields, Lead_Audit__c
│   ├── permissionsets/          # Lead_Tracker_User
│   ├── tabs/                    # Lead_Tracker + Lead_Tracker_Dashboard tabs
│   └── triggers/                # LeadTrigger (single trigger, handler-routed)
├── manifest/package.xml
├── sfdx-project.json
└── jest.config.js
```

---

## Naming Conventions

| Artifact | Convention | Example |
|----------|-----------|---------|
| Apex Classes | `Lead<Layer>` or `LeadTracker<Layer>` | `LeadTrackerSelector` |
| Test Classes | `<ClassName>_Test` | `LeadSelector_Test` |
| LWC Components | `lt<ComponentName>` (camelCase) | `ltLeadCard` |
| CMT Types | `LeadTracker_<Name>__mdt` | `Pipeline_Stage__mdt` |
| CMT Record Dev Names | `LT_<Name>` | `LT_Initial_Inquiry` |
| Permission Sets | `Lead_Tracker_<Role>` | `Lead_Tracker_User` |
| Custom Objects | `Lead_<Name>__c` | `Lead_Audit__c` |

---

## Development

```bash
# Lint LWC
npm run lint

# LWC Jest unit tests
npm run test:unit

# Apex tests with coverage
sf apex run test \
  --target-org sf-dev-edition-partner-org \
  --code-coverage \
  --result-format human \
  --wait 15
```

---

## Target Org

| Property | Value |
|----------|-------|
| Alias | `sf-dev-edition-partner-org` |
| Org Type | Developer Edition |
| API Version | 66.0 |

---

Built with enterprise standards for extensibility, maintainability, and AppExchange-readiness.
