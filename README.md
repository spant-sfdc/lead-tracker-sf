# Lead Tracker

A modern, enterprise-grade Salesforce application for pipeline management. Built natively on the Salesforce Platform with a metadata-driven architecture, console-first UX, and a clean service-layer pattern designed for future AppExchange packaging.

---

## Overview

Lead Tracker replaces manual pipeline management with a SaaS-like kanban board experience running entirely within Salesforce. Every aspect of the pipeline — stages, colors, icons, and branding — is controlled through Custom Metadata Types with zero hardcoding.

---

## Architecture

### Design Principles

| Principle | Implementation |
|-----------|----------------|
| Metadata-Driven | Custom Metadata Types control all pipeline stages, colors, icons, and app config |
| Service-Layer Pattern | Selector → Service → Controller → LWC layered architecture |
| Zero Hardcoding | No hardcoded stages, colors, or icons anywhere in code |
| One Trigger Per Object | Single `LeadTrigger` with `LeadTriggerHandler` routing all events |
| No SOQL in Loops | All queries centralized in `LeadTrackerSelector` |
| Console-First UI | Salesforce Console app with Lightning Web Components |
| SLDS-Compliant | All components use SLDS design tokens and patterns |
| Enterprise-Grade Tests | All Apex classes covered by dedicated `_Test` classes |

### Layer Architecture

```
┌─────────────────────────────────────────────────────┐
│                   LWC UI Layer                       │
│  ltPipelineBoard │ ltLeadCard │ ltAppHeader          │
│  ltBase (utilities/constants)                        │
└──────────────────────┬──────────────────────────────┘
                       │  @AuraEnabled
┌──────────────────────▼──────────────────────────────┐
│               Controller Layer                       │
│               LeadTrackerController                  │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│                Service Layer                         │
│                LeadTrackerService                    │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│               Selector Layer                         │
│               LeadTrackerSelector                    │
└──────────────────────┬──────────────────────────────┘
                       │  SOQL (USER_MODE)
┌──────────────────────▼──────────────────────────────┐
│             Salesforce Platform                      │
│   Lead (Standard Object) │ Custom Metadata Types     │
└─────────────────────────────────────────────────────┘
```

---

## Custom Metadata Types

### `LeadTracker_Pipeline_Stage__mdt`

Drives pipeline board columns. Every stage is a CMT record — never hardcoded.

| Field | Type | Purpose |
|-------|------|---------|
| `Stage_Name__c` | Text(255) | Maps to `Lead.Status` picklist value |
| `Sort_Order__c` | Number(3,0) | Column position on the pipeline board |
| `Icon_Name__c` | Text(100) | SLDS icon name (e.g., `standard:lead`) |
| `Color_Hex__c` | Text(7) | Column accent color in `#RRGGBB` format |
| `Is_Closed__c` | Checkbox | Marks this as a terminal/closed stage |
| `Is_Won__c` | Checkbox | Marks this as a won outcome stage |
| `Is_Active__c` | Checkbox | Enables/disables the stage on the board |
| `Description__c` | Text Area(500) | Human-readable stage description |

### `LeadTracker_App_Config__mdt`

Controls global application behavior and branding. Use Developer Name `Default` for org-wide settings.

| Field | Type | Purpose |
|-------|------|---------|
| `App_Name__c` | Text(100) | Application display name |
| `Primary_Color__c` | Text(7) | Primary brand color (`#RRGGBB`) |
| `Secondary_Color__c` | Text(7) | Secondary brand color (`#RRGGBB`) |
| `Logo_Static_Resource__c` | Text(100) | Static resource name for the logo asset |
| `Support_Email__c` | Email | Support contact email |
| `Default_Tab__c` | Text(80) | Default landing tab API name |

---

## Project Structure

```
lead-tracker-sf/
├── force-app/main/default/
│   ├── applications/
│   │   └── LeadTracker.app-meta.xml              # Console app definition
│   ├── classes/
│   │   ├── LeadTrackerException.cls               # Custom exception type
│   │   ├── LeadTrackerSelector.cls                # SOQL data access layer
│   │   ├── LeadTrackerSelector_Test.cls
│   │   ├── LeadTrackerService.cls                 # Business logic layer
│   │   ├── LeadTrackerService_Test.cls
│   │   ├── LeadTrackerController.cls              # @AuraEnabled LWC controller
│   │   ├── LeadTrackerController_Test.cls
│   │   ├── LeadTriggerHandler.cls                 # Trigger event router
│   │   └── LeadTriggerHandler_Test.cls
│   ├── customMetadata/
│   │   ├── LeadTracker_Pipeline_Stage.LT_Open_Not_Contacted.md-meta.xml
│   │   ├── LeadTracker_Pipeline_Stage.LT_Working_Contacted.md-meta.xml
│   │   ├── LeadTracker_Pipeline_Stage.LT_Closed_Converted.md-meta.xml
│   │   ├── LeadTracker_Pipeline_Stage.LT_Closed_Not_Converted.md-meta.xml
│   │   └── LeadTracker_App_Config.Default.md-meta.xml
│   ├── flexipages/
│   │   └── Lead_Tracker_Home.flexipage-meta.xml
│   ├── labels/
│   │   └── CustomLabels.labels-meta.xml           # All UI string labels
│   ├── lwc/
│   │   ├── ltBase/                                # Shared utility module
│   │   ├── ltAppHeader/                           # App branding header
│   │   ├── ltPipelineBoard/                       # Main kanban board
│   │   └── ltLeadCard/                            # Individual lead card
│   ├── objects/
│   │   ├── LeadTracker_Pipeline_Stage__mdt/       # CMT object + field definitions
│   │   └── LeadTracker_App_Config__mdt/           # CMT object + field definitions
│   ├── permissionsets/
│   │   └── Lead_Tracker_User.permissionset-meta.xml
│   ├── tabs/
│   │   └── Lead_Tracker.tab-meta.xml
│   └── triggers/
│       └── LeadTrigger.trigger                    # Single trigger, all events
├── config/
│   └── project-scratch-def.json
├── manifest/
│   └── package.xml
├── scripts/
│   ├── apex/                                      # Anonymous Apex scripts
│   └── soql/                                      # SOQL query reference scripts
└── sfdx-project.json
```

---

## Deployment Guide

### Prerequisites

- Salesforce CLI (`sf`) v2.x+
- Node.js 18+
- Authorized Salesforce Developer Edition org

### Deploy to Connected Org

```bash
# Verify org connection
sf org display --target-org sf-dev-edition-partner-org

# Deploy all metadata
sf project deploy start \
  --source-dir force-app \
  --target-org sf-dev-edition-partner-org \
  --wait 15

# Run all Apex tests with coverage
sf apex run test \
  --target-org sf-dev-edition-partner-org \
  --code-coverage \
  --result-format human \
  --wait 15

# Assign permission set to current user
sf org assign permset \
  --name Lead_Tracker_User \
  --target-org sf-dev-edition-partner-org

# Open the org
sf org open --target-org sf-dev-edition-partner-org
```

### Working with Scratch Orgs

```bash
# Create scratch org (requires Dev Hub)
sf org create scratch \
  --definition-file config/project-scratch-def.json \
  --alias lead-tracker-scratch \
  --duration-days 30

# Deploy, assign perm set, open
sf project deploy start --source-dir force-app --target-org lead-tracker-scratch
sf org assign permset --name Lead_Tracker_User --target-org lead-tracker-scratch
sf org open --target-org lead-tracker-scratch
```

---

## Metadata Strategy

### Deployment Order (for new orgs)

1. `CustomObject` — CMT type definitions
2. `CustomMetadata` — CMT records (pipeline stages, app config)
3. `CustomLabels`
4. `ApexClass` — in dependency order: Exception → Selector → Service → Controller → Handler
5. `ApexTrigger`
6. `LightningComponentBundle`
7. `CustomTab`
8. `CustomApplication`
9. `FlexiPage`
10. `PermissionSet`

### Naming Conventions

| Artifact | Convention | Example |
|----------|-----------|---------|
| Apex Classes | `LeadTracker<Layer>` | `LeadTrackerSelector` |
| Trigger | `<Object>Trigger` | `LeadTrigger` |
| Trigger Handler | `<Object>TriggerHandler` | `LeadTriggerHandler` |
| Test Classes | `<ClassName>_Test` | `LeadTrackerSelector_Test` |
| LWC Components | `lt<ComponentName>` | `ltPipelineBoard` |
| CMT Types | `LeadTracker_<Name>__mdt` | `LeadTracker_Pipeline_Stage__mdt` |
| CMT Records (Dev Name) | `LT_<Name>` | `LT_Open_Not_Contacted` |
| Custom Labels | `LT_<Description>` | `LT_App_Title` |
| Permission Sets | `Lead_Tracker_<Role>` | `Lead_Tracker_User` |

### Adding a New Pipeline Stage

Never hardcode stages. Add a Custom Metadata record:

```xml
<!-- force-app/main/default/customMetadata/LeadTracker_Pipeline_Stage.LT_Your_Stage.md-meta.xml -->
<CustomMetadata>
    <label>LT - Your Stage</label>
    <values>
        <field>Stage_Name__c</field>
        <value>Your Lead Status Value</value>  <!-- must match Lead.Status picklist -->
    </values>
    <values>
        <field>Sort_Order__c</field>
        <value>5</value>
    </values>
    ...
</CustomMetadata>
```

---

## Phase Plan

### Phase 1: Foundation (Current — Complete)
- [x] SFDX project initialization with API v66.0
- [x] Salesforce org authentication (`sf-dev-edition-partner-org`)
- [x] Custom Metadata Type object definitions + field schema
- [x] Custom Metadata Records (4 pipeline stages + app config)
- [x] Service-layer Apex architecture (Selector / Service / Controller)
- [x] Trigger framework — one trigger, handler-routed
- [x] LWC component scaffold (ltBase, ltAppHeader, ltPipelineBoard, ltLeadCard)
- [x] Console app definition
- [x] Custom labels for all UI strings
- [x] Permission set for Lead Tracker users
- [x] Git repository with clean structure and `.gitignore`

### Phase 2: Pipeline Board UI
- [ ] Full kanban board rendering in `ltPipelineBoard`
- [ ] Drag-and-drop lead movement between stages
- [ ] Stage column headers with configurable colors/icons
- [ ] Real-time stage count badges
- [ ] Empty-state handling per column

### Phase 3: Lead Management
- [ ] Lead detail side panel (splitview console)
- [ ] Inline edit for key lead fields
- [ ] Activity timeline integration
- [ ] Lead conversion flow trigger from board
- [ ] Smart lead scoring/rating display

### Phase 4: Analytics
- [ ] Pipeline velocity metrics
- [ ] Stage conversion rate cards
- [ ] Configurable dashboard (`ltDashboard`)
- [ ] CSV/Excel export

### Phase 5: Advanced Features
- [ ] Advanced filtering (owner, source, date, score)
- [ ] Saved named views
- [ ] Configurable lead card field sets
- [ ] Quick email/activity log from board card
- [ ] Mobile-responsive layout

### Phase 6: Packaging
- [ ] Second-Generation Package (2GP) setup
- [ ] Namespace configuration
- [ ] Version management pipeline
- [ ] AppExchange security review prep

---

## Development Commands

```bash
# Lint LWC
npm run lint

# Format all files
npm run prettier

# Run LWC Jest unit tests
npm run test:unit

# Run Apex tests
sf apex run test --target-org sf-dev-edition-partner-org --code-coverage --result-format human --wait 15
```

---

## Target Org

| Property | Value |
|----------|-------|
| Alias | `sf-dev-edition-partner-org` |
| Username | `spant.38bdf20c3c08@agentforce.com` |
| Org Type | Developer Edition |
| API Version | 66.0 |

---

Built with enterprise standards for extensibility, maintainability, and AppExchange-readiness.
