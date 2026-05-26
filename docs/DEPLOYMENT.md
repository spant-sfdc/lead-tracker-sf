# Deployment Guide

Complete step-by-step guide for deploying Lead Tracker to a Salesforce org.

---

## Prerequisites

| Requirement | Version | Notes |
|-------------|---------|-------|
| Salesforce CLI (`sf`) | v2.x+ | `sf --version` to verify |
| Node.js | 18+ | Required for LWC tooling |
| Git | Any | For source control |
| Salesforce Org | Developer Edition or Sandbox | Production requires change sets or pipeline |

---

## 1. Authenticate with Your Org

```bash
# Interactive browser login (recommended)
sf org login web --alias sf-dev-edition-partner-org

# Or JWT-based auth for CI/CD
sf org login jwt \
  --client-id <CONNECTED_APP_CLIENT_ID> \
  --jwt-key-file server.key \
  --username your-user@example.com \
  --alias sf-dev-edition-partner-org

# Verify the connection
sf org display --target-org sf-dev-edition-partner-org
```

---

## 2. Deploy Metadata

### Full Deployment (recommended for first deploy)

```bash
sf project deploy start \
  --source-dir force-app \
  --target-org sf-dev-edition-partner-org \
  --wait 15
```

### Targeted Deployment (for incremental updates)

Deploy specific component types to minimize risk:

```bash
# Apex classes only
sf project deploy start \
  --metadata "ApexClass:LeadController" \
  --metadata "ApexClass:LeadService" \
  --metadata "ApexClass:LeadSelector" \
  --metadata "ApexClass:LeadTrackerController" \
  --metadata "ApexClass:LeadTrackerService" \
  --metadata "ApexClass:LeadTrackerSelector" \
  --metadata "ApexClass:LeadTrackerDTO" \
  --metadata "ApexClass:LeadTriggerHandler" \
  --target-org sf-dev-edition-partner-org

# LWC components only
sf project deploy start \
  --metadata "LightningComponentBundle:ltPipelineWorkspace" \
  --metadata "LightningComponentBundle:ltDashboard" \
  --metadata "LightningComponentBundle:ltLeadCard" \
  --metadata "LightningComponentBundle:ltKanbanColumn" \
  --metadata "LightningComponentBundle:ltLeadDrawer" \
  --target-org sf-dev-edition-partner-org

# Custom Metadata records
sf project deploy start \
  --metadata "CustomMetadata:Pipeline_Stage.LT_Initial_Inquiry" \
  --metadata "CustomMetadata:Pipeline_Stage.LT_Discovery_Call" \
  --metadata "CustomMetadata:Pipeline_Stage.LT_Needs_Assessment" \
  --metadata "CustomMetadata:Pipeline_Stage.LT_Proposal_Submitted" \
  --metadata "CustomMetadata:Pipeline_Stage.LT_Partnership_Confirmed" \
  --metadata "CustomMetadata:Pipeline_Stage.LT_Long_Term_Nurture" \
  --metadata "CustomMetadata:Pipeline_Stage.LT_Not_A_Fit" \
  --target-org sf-dev-edition-partner-org
```

---

## 3. Run Apex Tests

Always run tests after deployment to verify no regressions:

```bash
sf apex run test \
  --target-org sf-dev-edition-partner-org \
  --code-coverage \
  --result-format human \
  --wait 15
```

Expected: all tests pass, ≥ 75% code coverage on all Apex classes.

---

## 4. Assign Permission Set

Every user who needs access to Lead Tracker must have the `Lead_Tracker_User` permission set:

```bash
# Assign to yourself
sf org assign permset \
  --name Lead_Tracker_User \
  --target-org sf-dev-edition-partner-org

# Assign to a specific user
sf org assign permset \
  --name Lead_Tracker_User \
  --on-behalf-of other.user@example.com \
  --target-org sf-dev-edition-partner-org
```

Or via Setup > Permission Sets > Lead Tracker User > Manage Assignments.

---

## 5. Verify Custom Metadata Records

Navigate to Setup > Custom Metadata Types and verify:

- **Pipeline Stage** — should have 7 records: Initial Inquiry, Discovery Call, Needs Assessment, Proposal Submitted, Partnership Confirmed, Long Term Nurture, Not A Fit
- **LeadTracker App Config** — should have 1 record: Default

If missing, deploy them:

```bash
sf project deploy start \
  --source-dir force-app/main/default/customMetadata \
  --target-org sf-dev-edition-partner-org
```

---

## 6. Open the App

```bash
sf org open --target-org sf-dev-edition-partner-org
```

Navigate to the **Lead Tracker** app from the App Launcher. You should see two tabs:
- **Lead Tracker** — the kanban pipeline board
- **Pipeline Analytics** — the analytics dashboard

---

## Scratch Org Setup (Development)

For local development with a fresh scratch org:

```bash
# Requires Dev Hub enabled in your org
sf org create scratch \
  --definition-file config/project-scratch-def.json \
  --alias lead-tracker-scratch \
  --duration-days 30 \
  --set-default

sf project deploy start --source-dir force-app --target-org lead-tracker-scratch
sf org assign permset --name Lead_Tracker_User --target-org lead-tracker-scratch

# Load sample data (if available)
sf data import tree --files scripts/data/leads.json --target-org lead-tracker-scratch

sf org open --target-org lead-tracker-scratch
```

---

## Deployment Order (for brand-new orgs)

If deploying to a completely fresh org with no prior metadata, follow this order to respect dependencies:

1. **Custom Objects** — `Lead_Audit__c`, CMT type object definitions
2. **Custom Fields** — Lead field extensions (`Current_Stage__c`, `Engagement_Score__c`, etc.)
3. **Custom Metadata Records** — Pipeline stages + App Config
4. **Custom Labels**
5. **Apex Classes** — in this order:
   - `LeadTrackerException`
   - `LeadTrackerDTO`
   - Selectors (`LeadTrackerSelector`, `LeadSelector`, `LeadAuditSelector`)
   - Services (`LeadTrackerService`, `LeadService`, `LeadAuditService`)
   - Controllers (`LeadTrackerController`, `LeadController`)
   - Handler (`LeadTriggerHandler`)
   - Test classes (any order)
6. **Apex Trigger** — `LeadTrigger`
7. **LWC Components** — any order (all peer dependencies)
8. **Custom Tabs** — `Lead_Tracker`, `Lead_Tracker_Dashboard`
9. **Custom Application** — `LeadTracker`
10. **Permission Set** — `Lead_Tracker_User`

---

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| Deploy fails: "No org found" | Not authenticated | Run `sf org login web --alias ...` |
| Deploy fails: "Invalid field" | Missing custom field on Lead | Deploy `objects/Lead/` first |
| Test failures: UNABLE_TO_LOCK_ROW | Concurrent test data conflict | Rerun tests; use `@IsTest(SeeAllData=false)` |
| Board shows no stages | CMT records not deployed or `Is_Active__c` = false | Deploy `customMetadata/` and verify records |
| Permission denied errors | User lacks permission set | Assign `Lead_Tracker_User` permission set |
| Tab not visible | App not added to nav | Open App Launcher and search for "Lead Tracker" |

---

## CI/CD Notes

- All SOQL uses `WITH USER_MODE` — FLS and CRUP enforced at the database level; no manual field stripping needed.
- The trigger is bulkified — safe for data loads and batch operations.
- No static references to org IDs, User IDs, or hardcoded picklist values anywhere in the codebase.
- API version: **66.0** (set in `sfdx-project.json` and all `*-meta.xml` files).
