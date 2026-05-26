/**
 * Demo Data Cleanup — TechPulse Lead Tracker
 *
 * Run via:
 *   sf apex run --file scripts/apex/cleanupDemoData.apex --target-org sf-dev-edition-partner-org
 *
 * WHAT THIS REMOVES:
 *   • Leads whose Company contains '[Demo]' (seed script marker)
 *   • Tasks, Lead_Audit__c records, Notes, and ContentDocuments linked to those leads
 *   • Converted Accounts, Contacts, and Opportunities if any demo leads were converted
 *   • Orphaned Lead_Audit__c records whose parent Lead no longer exists (SetNull cleanup)
 *
 * WHAT THIS PRESERVES:
 *   • All Apex classes, LWCs, FlexiPages, Tabs, PermissionSets, App metadata
 *   • All Custom Metadata (Pipeline_Stage__mdt, Application_Config__mdt)
 *   • Any non-demo Leads, Accounts, Contacts, Opportunities, Tasks
 *   • Dashboards, Reports, Layouts, Labels
 *
 * IMPORTANT: Lead_Audit__c uses deleteConstraint=SetNull, so audits must be
 * deleted before their parent leads or they become unidentifiable orphans.
 */

// ── 1. Identify demo leads ─────────────────────────────────────────────────────
List<Lead> demoLeads = [
    SELECT Id, Company, IsConverted,
           ConvertedAccountId, ConvertedContactId, ConvertedOpportunityId
    FROM   Lead
    WHERE  Company LIKE '%[Demo]%'
    LIMIT  500
];

if (demoLeads.isEmpty()) {
    System.debug('No demo leads found. Nothing to clean up.');
    return;
}

Set<Id> leadIds = new Set<Id>();
Set<Id> convAccountIds  = new Set<Id>();
Set<Id> convContactIds  = new Set<Id>();
Set<Id> convOppIds      = new Set<Id>();

for (Lead l : demoLeads) {
    leadIds.add(l.Id);
    if (l.IsConverted) {
        if (l.ConvertedAccountId    != null) convAccountIds.add(l.ConvertedAccountId);
        if (l.ConvertedContactId    != null) convContactIds.add(l.ConvertedContactId);
        if (l.ConvertedOpportunityId != null) convOppIds.add(l.ConvertedOpportunityId);
    }
}
System.debug('[1] Demo leads identified: ' + leadIds.size());

// ── 2. Delete Tasks linked to demo leads ───────────────────────────────────────
List<Task> tasks = [SELECT Id FROM Task WHERE WhoId IN :leadIds LIMIT 500];
if (!tasks.isEmpty()) {
    List<Database.DeleteResult> dr = Database.delete(tasks, false);
    Integer ok = 0; Integer fail = 0;
    for (Database.DeleteResult r : dr) { if (r.isSuccess()) ok++; else fail++; }
    System.debug('[2] Tasks deleted: ' + ok + (fail > 0 ? ' | FAILED: ' + fail : ''));
} else {
    System.debug('[2] Tasks deleted: 0');
}

// ── 3. Delete Lead_Audit__c records before leads (SetNull constraint) ──────────
List<Lead_Audit__c> audits = [
    SELECT Id FROM Lead_Audit__c WHERE Lead__c IN :leadIds LIMIT 500
];
if (!audits.isEmpty()) {
    List<Database.DeleteResult> dr = Database.delete(audits, false);
    Integer ok = 0; Integer fail = 0;
    for (Database.DeleteResult r : dr) { if (r.isSuccess()) ok++; else fail++; }
    System.debug('[3] Lead_Audit__c records deleted: ' + ok + (fail > 0 ? ' | FAILED: ' + fail : ''));
} else {
    System.debug('[3] Lead_Audit__c records deleted: 0');
}

// ── 4. Delete Notes attached to demo leads ─────────────────────────────────────
List<Note> notes = [SELECT Id FROM Note WHERE ParentId IN :leadIds LIMIT 500];
if (!notes.isEmpty()) {
    List<Database.DeleteResult> dr = Database.delete(notes, false);
    Integer ok = 0; Integer fail = 0;
    for (Database.DeleteResult r : dr) { if (r.isSuccess()) ok++; else fail++; }
    System.debug('[4] Notes deleted: ' + ok + (fail > 0 ? ' | FAILED: ' + fail : ''));
} else {
    System.debug('[4] Notes deleted: 0');
}

// ── 5. Delete ContentDocumentLinks + ContentDocuments for demo leads ───────────
List<ContentDocumentLink> cdLinks = [
    SELECT Id, ContentDocumentId
    FROM   ContentDocumentLink
    WHERE  LinkedEntityId IN :leadIds
    LIMIT  500
];
if (!cdLinks.isEmpty()) {
    // Only delete a ContentDocument if it is NOT shared with any non-demo entity
    Set<Id> docIds = new Set<Id>();
    for (ContentDocumentLink cdl : cdLinks) docIds.add(cdl.ContentDocumentId);

    List<ContentDocumentLink> externalLinks = [
        SELECT ContentDocumentId
        FROM   ContentDocumentLink
        WHERE  ContentDocumentId IN :docIds
        AND    LinkedEntityId NOT IN :leadIds
    ];
    Set<Id> sharedDocIds = new Set<Id>();
    for (ContentDocumentLink cdl : externalLinks) sharedDocIds.add(cdl.ContentDocumentId);

    Set<Id> exclusiveDocIds = new Set<Id>(docIds);
    exclusiveDocIds.removeAll(sharedDocIds);

    // Delete the links first
    Database.delete(cdLinks, false);
    System.debug('[5a] ContentDocumentLinks deleted: ' + cdLinks.size());

    // Then delete documents that were exclusively linked to demo leads
    if (!exclusiveDocIds.isEmpty()) {
        List<ContentDocument> docs = [
            SELECT Id FROM ContentDocument WHERE Id IN :exclusiveDocIds
        ];
        if (!docs.isEmpty()) {
            Database.delete(docs, false);
            System.debug('[5b] ContentDocuments deleted: ' + docs.size());
        }
    }
    System.debug('[5b] Shared documents preserved (linked elsewhere): ' + sharedDocIds.size());
} else {
    System.debug('[5] ContentDocumentLinks deleted: 0');
}

// ── 6. Delete demo leads ───────────────────────────────────────────────────────
List<Database.DeleteResult> leadResults = Database.delete(demoLeads, false);
Integer leadOk = 0; Integer leadFail = 0;
for (Database.DeleteResult r : leadResults) { if (r.isSuccess()) leadOk++; else leadFail++; }
System.debug('[6] Leads deleted: ' + leadOk + (leadFail > 0 ? ' | FAILED: ' + leadFail : ''));

// ── 7. Delete converted Opportunities (before Contacts/Accounts) ──────────────
if (!convOppIds.isEmpty()) {
    List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE Id IN :convOppIds];
    if (!opps.isEmpty()) {
        Database.delete(opps, false);
        System.debug('[7] Converted Opportunities deleted: ' + opps.size());
    }
} else {
    System.debug('[7] No converted Opportunities found.');
}

// ── 8. Delete converted Contacts ──────────────────────────────────────────────
if (!convContactIds.isEmpty()) {
    List<Contact> contacts = [SELECT Id FROM Contact WHERE Id IN :convContactIds];
    if (!contacts.isEmpty()) {
        Database.delete(contacts, false);
        System.debug('[8] Converted Contacts deleted: ' + contacts.size());
    }
} else {
    System.debug('[8] No converted Contacts found.');
}

// ── 9. Delete converted Accounts (only if they have no remaining children) ─────
if (!convAccountIds.isEmpty()) {
    // Guard: skip accounts that still have live contacts or opportunities
    Set<Id> accountsWithChildren = new Set<Id>();
    for (Contact c : [SELECT AccountId FROM Contact WHERE AccountId IN :convAccountIds]) {
        accountsWithChildren.add(c.AccountId);
    }
    for (Opportunity o : [SELECT AccountId FROM Opportunity WHERE AccountId IN :convAccountIds]) {
        accountsWithChildren.add(o.AccountId);
    }
    Set<Id> safeToDeleteAccounts = new Set<Id>(convAccountIds);
    safeToDeleteAccounts.removeAll(accountsWithChildren);

    if (!safeToDeleteAccounts.isEmpty()) {
        List<Account> accounts = [SELECT Id FROM Account WHERE Id IN :safeToDeleteAccounts];
        Database.delete(accounts, false);
        System.debug('[9] Converted Accounts deleted: ' + accounts.size());
    }
    if (!accountsWithChildren.isEmpty()) {
        System.debug('[9] Accounts skipped (still have live children): ' + accountsWithChildren.size());
    }
} else {
    System.debug('[9] No converted Accounts found.');
}

// ── 10. Clean up orphaned Lead_Audit__c records (Lead__c = null) ──────────────
// Catches audits left over from any prior partial deletions
List<Lead_Audit__c> orphans = [
    SELECT Id FROM Lead_Audit__c WHERE Lead__c = null LIMIT 500
];
if (!orphans.isEmpty()) {
    Database.delete(orphans, false);
    System.debug('[10] Orphaned Lead_Audit__c records cleaned: ' + orphans.size());
} else {
    System.debug('[10] No orphaned Lead_Audit__c records found.');
}

// ── Summary ────────────────────────────────────────────────────────────────────
System.debug('');
System.debug('=== Cleanup complete. Run validation queries to confirm. ===');
System.debug('');
System.debug('VALIDATION QUERIES:');
System.debug('  [Lead]         SELECT COUNT() FROM Lead WHERE Company LIKE \'%[Demo]%\'');
System.debug('  [Audit]        SELECT COUNT() FROM Lead_Audit__c');
System.debug('  [Audit orphan] SELECT COUNT() FROM Lead_Audit__c WHERE Lead__c = null');
System.debug('  [Task]         SELECT COUNT() FROM Task WHERE WhoId IN (SELECT Id FROM Lead WHERE Company LIKE \'%[Demo]%\')');
System.debug('  [Note]         SELECT COUNT() FROM Note WHERE ParentId IN (SELECT Id FROM Lead WHERE Company LIKE \'%[Demo]%\')');
