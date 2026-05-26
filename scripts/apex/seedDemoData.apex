/**
 * Demo Seed Data — TechPulse Lead Tracker
 * Run via: sf apex run --file scripts/apex/seedDemoData.apex --target-org sf-dev-edition-partner-org
 *
 * Creates 25 realistic nonprofit leads across all pipeline stages with tasks and notes.
 * Safe to re-run: deletes existing demo leads (Company contains '[Demo]') first.
 */

// ── 1. Clean up previous demo data ────────────────────────────────────────────
List<Lead> existing = [SELECT Id FROM Lead WHERE Company LIKE '%[Demo]%' LIMIT 200];
if (!existing.isEmpty()) {
    delete existing;
    System.debug('Deleted ' + existing.size() + ' existing demo leads.');
}

// ── 2. Discover active pipeline stages from CMT ────────────────────────────────
List<Pipeline_Stage__mdt> stages = [
    SELECT Stage_Key__c, Stage_Label__c, Sequence__c
    FROM   Pipeline_Stage__mdt
    ORDER  BY Sequence__c ASC
    LIMIT  20
];

if (stages.isEmpty()) {
    System.debug('ERROR: No Pipeline_Stage__mdt records found. Deploy CMT records first.');
    return;
}

List<String> stageKeys = new List<String>();
for (Pipeline_Stage__mdt s : stages) {
    stageKeys.add(s.Stage_Key__c);
}
System.debug('Found stages: ' + stageKeys);

// ── 3. Define nonprofit lead data ──────────────────────────────────────────────
List<Map<String,Object>> defs = new List<Map<String,Object>>{
    new Map<String,Object>{ 'first'=>'Maya',    'last'=>'Thornton',  'company'=>'Green Future Foundation [Demo]',        'email'=>'m.thornton@greenfuture.org',     'title'=>'Executive Director',    'size'=>'51-200',   'crm'=>'Salesforce',  'pipeline'=>'Enterprise' },
    new Map<String,Object>{ 'first'=>'Carlos',  'last'=>'Rivera',    'company'=>'United Voices Nonprofit [Demo]',         'email'=>'c.rivera@unitedvoices.org',      'title'=>'Programs Director',     'size'=>'11-50',    'crm'=>'HubSpot',     'pipeline'=>'SMB' },
    new Map<String,Object>{ 'first'=>'Priya',   'last'=>'Sharma',    'company'=>'Education Access Alliance [Demo]',       'email'=>'p.sharma@edaccess.org',          'title'=>'Development Manager',   'size'=>'201-500',  'crm'=>'None',        'pipeline'=>'Enterprise' },
    new Map<String,Object>{ 'first'=>'James',   'last'=>'Okafor',    'company'=>'Community Health First [Demo]',          'email'=>'j.okafor@commhealthfirst.org',   'title'=>'CEO',                   'size'=>'51-200',   'crm'=>'Zoho',        'pipeline'=>'Enterprise' },
    new Map<String,Object>{ 'first'=>'Sofia',   'last'=>'Martinez',  'company'=>'Hope Harbor Society [Demo]',             'email'=>'s.martinez@hopeharbor.org',      'title'=>'Founder',               'size'=>'1-10',     'crm'=>'None',        'pipeline'=>'SMB' },
    new Map<String,Object>{ 'first'=>'Liam',    'last'=>'Chen',      'company'=>'Clean Water Initiative [Demo]',          'email'=>'l.chen@cleanwater.org',          'title'=>'Operations Director',   'size'=>'11-50',    'crm'=>'Salesforce',  'pipeline'=>'SMB' },
    new Map<String,Object>{ 'first'=>'Amara',   'last'=>'Johnson',   'company'=>'Youth Empowerment Network [Demo]',       'email'=>'a.johnson@youthempowerment.org', 'title'=>'Executive Director',    'size'=>'51-200',   'crm'=>'HubSpot',     'pipeline'=>'Enterprise' },
    new Map<String,Object>{ 'first'=>'Noah',    'last'=>'Patel',     'company'=>'Digital Literacy Fund [Demo]',           'email'=>'n.patel@digliteracy.org',        'title'=>'Technology Director',   'size'=>'1-10',     'crm'=>'None',        'pipeline'=>'SMB' },
    new Map<String,Object>{ 'first'=>'Elena',   'last'=>'Williams',  'company'=>'Veterans Support Coalition [Demo]',      'email'=>'e.williams@vetsupport.org',      'title'=>'Program Manager',       'size'=>'201-500',  'crm'=>'Microsoft',   'pipeline'=>'Enterprise' },
    new Map<String,Object>{ 'first'=>'Marcus',  'last'=>'Green',     'company'=>'Arts for All Foundation [Demo]',         'email'=>'m.green@artsforall.org',         'title'=>'Managing Director',     'size'=>'11-50',    'crm'=>'Zoho',        'pipeline'=>'SMB' },
    new Map<String,Object>{ 'first'=>'Fatima',  'last'=>'Hassan',    'company'=>'Hunger Relief Network [Demo]',           'email'=>'f.hassan@hungerrelief.org',      'title'=>'CEO',                   'size'=>'201-500',  'crm'=>'Salesforce',  'pipeline'=>'Enterprise' },
    new Map<String,Object>{ 'first'=>'Daniel',  'last'=>'Kim',       'company'=>'Environmental Justice League [Demo]',    'email'=>'d.kim@envjustice.org',           'title'=>'Advocacy Director',     'size'=>'51-200',   'crm'=>'HubSpot',     'pipeline'=>'Enterprise' },
    new Map<String,Object>{ 'first'=>'Aisha',   'last'=>'Thompson',  'company'=>'Global Learning Partnership [Demo]',     'email'=>'a.thompson@globallearning.org',  'title'=>'COO',                   'size'=>'501+',     'crm'=>'Salesforce',  'pipeline'=>'Enterprise' },
    new Map<String,Object>{ 'first'=>'Ryan',    'last'=>'O\'Brien',  'company'=>'Senior Care Connect [Demo]',             'email'=>'r.obrien@seniorcare.org',        'title'=>'Executive Director',    'size'=>'51-200',   'crm'=>'None',        'pipeline'=>'SMB' },
    new Map<String,Object>{ 'first'=>'Zara',    'last'=>'Ahmed',     'company'=>'Animal Welfare Alliance [Demo]',         'email'=>'z.ahmed@animalwelfare.org',      'title'=>'Development Director',  'size'=>'11-50',    'crm'=>'Bloomerang',  'pipeline'=>'SMB' },
    new Map<String,Object>{ 'first'=>'Tyler',   'last'=>'Brooks',    'company'=>'Mental Health Advocates [Demo]',         'email'=>'t.brooks@mhadvocates.org',       'title'=>'Programs VP',           'size'=>'201-500',  'crm'=>'Salesforce',  'pipeline'=>'Enterprise' },
    new Map<String,Object>{ 'first'=>'Layla',   'last'=>'Nguyen',    'company'=>'Refugee Resource Center [Demo]',         'email'=>'l.nguyen@refugeeresource.org',   'title'=>'Director',              'size'=>'51-200',   'crm'=>'HubSpot',     'pipeline'=>'Enterprise' },
    new Map<String,Object>{ 'first'=>'Ethan',   'last'=>'Rosario',   'company'=>'Literacy Bridge International [Demo]',   'email'=>'e.rosario@literacybridge.org',   'title'=>'Founder & CEO',         'size'=>'11-50',    'crm'=>'None',        'pipeline'=>'SMB' },
    new Map<String,Object>{ 'first'=>'Grace',   'last'=>'Liu',       'company'=>'Women in STEM Foundation [Demo]',        'email'=>'g.liu@womeninstem.org',          'title'=>'Executive Director',    'size'=>'51-200',   'crm'=>'Salesforce',  'pipeline'=>'Enterprise' },
    new Map<String,Object>{ 'first'=>'Jordan',  'last'=>'Miller',    'company'=>'Rural Development Alliance [Demo]',      'email'=>'j.miller@ruraldevelopment.org',  'title'=>'Strategy Director',     'size'=>'11-50',    'crm'=>'Zoho',        'pipeline'=>'SMB' },
    new Map<String,Object>{ 'first'=>'Chloe',   'last'=>'Davis',     'company'=>'Urban Gardens Initiative [Demo]',        'email'=>'c.davis@urbangardens.org',       'title'=>'Program Coordinator',   'size'=>'1-10',     'crm'=>'None',        'pipeline'=>'SMB' },
    new Map<String,Object>{ 'first'=>'Isaiah',  'last'=>'Robinson',  'company'=>'Social Justice Collective [Demo]',       'email'=>'i.robinson@socialjustice.org',   'title'=>'Executive Director',    'size'=>'51-200',   'crm'=>'HubSpot',     'pipeline'=>'Enterprise' },
    new Map<String,Object>{ 'first'=>'Mia',     'last'=>'Taylor',    'company'=>'Tech for Good Labs [Demo]',              'email'=>'m.taylor@techforgood.org',       'title'=>'CTO',                   'size'=>'11-50',    'crm'=>'Salesforce',  'pipeline'=>'SMB' },
    new Map<String,Object>{ 'first'=>'Omar',    'last'=>'Farooq',    'company'=>'Mindful Schools Network [Demo]',         'email'=>'o.farooq@mindfulschools.org',    'title'=>'COO',                   'size'=>'201-500',  'crm'=>'Microsoft',   'pipeline'=>'Enterprise' },
    new Map<String,Object>{ 'first'=>'Nadia',   'last'=>'Castillo',  'company'=>'Coastal Conservation Trust [Demo]',      'email'=>'n.castillo@coastalconserve.org', 'title'=>'Development Manager',   'size'=>'51-200',   'crm'=>'Bloomerang',  'pipeline'=>'Enterprise' }
};

// Stage distribution across 25 leads
Integer stageCount = stageKeys.size();
List<Integer> scoreValues  = new List<Integer>{ 85,72,68,91,45,33,78,55,62,88,
                                                 41,76,94,59,37,82,67,73,48,86,
                                                 71,53,90,44,79 };
List<String>  healthValues = new List<String>{   'Healthy','Healthy','At Risk','Healthy','Critical',
                                                  'At Risk','Healthy','At Risk','Healthy','Healthy',
                                                  'Critical','Healthy','Healthy','At Risk','Critical',
                                                  'Healthy','At Risk','Healthy','At Risk','Healthy',
                                                  'Healthy','Critical','Healthy','At Risk','Healthy' };
List<Boolean> staleValues  = new List<Boolean>{  false,false,false,false,true,
                                                  true,false,false,false,false,
                                                  true,false,false,true,false,
                                                  false,false,false,true,false,
                                                  false,true,false,false,false };

// ── 4. Build and insert leads ──────────────────────────────────────────────────
List<Lead> leadsToInsert = new List<Lead>();
Date today = Date.today();

for (Integer i = 0; i < defs.size(); i++) {
    Map<String,Object> d = defs[i];
    Integer stageIdx = Math.mod(i, stageCount);
    String  stageKey = stageKeys[stageIdx];

    Lead l = new Lead();
    l.FirstName          = (String) d.get('first');
    l.LastName           = (String) d.get('last');
    l.Company            = (String) d.get('company');
    l.Email              = (String) d.get('email');
    l.Title              = (String) d.get('title');
    l.Current_Stage__c   = stageKey;
    l.Pipeline_Type__c   = (String) d.get('pipeline');
    l.Engagement_Score__c= scoreValues[i];
    l.Lead_Health__c     = healthValues[i];
    l.Is_Stale__c        = staleValues[i];
    l.Organization_Size__c = (String) d.get('size');
    l.Current_CRM__c     = (String) d.get('crm');
    l.Primary_Stakeholder__c = (String) d.get('first') + ' ' + (String) d.get('last');
    l.Phone              = '(555) ' + String.valueOf(100 + i).right(3) + '-' + String.valueOf(1000 + i * 7).right(4);
    l.Status             = 'Open - Not Contacted';

    // Assign follow-up dates — some overdue, some upcoming, some none
    Integer dayOffset = Math.mod(i, 5);
    if      (dayOffset == 0) l.Next_Follow_Up__c = today.addDays(-3);   // overdue
    else if (dayOffset == 1) l.Next_Follow_Up__c = today;               // today
    else if (dayOffset == 2) l.Next_Follow_Up__c = today.addDays(3);    // upcoming
    else if (dayOffset == 3) l.Next_Follow_Up__c = today.addDays(7);    // this week
    // dayOffset == 4: no follow-up date

    // Last activity — some recent, some stale
    if (staleValues[i]) {
        l.Last_Activity_Date__c = today.addDays(-45);
    } else {
        l.Last_Activity_Date__c = today.addDays(-1 * Math.mod(i, 10));
    }

    leadsToInsert.add(l);
}

insert leadsToInsert;
System.debug('Inserted ' + leadsToInsert.size() + ' demo leads.');

// ── 5. Seed tasks for the first 15 leads ──────────────────────────────────────
List<Task> tasks = new List<Task>();
List<String> taskSubjects = new List<String>{
    'Follow-up call re: partnership proposal',
    'Send product overview deck',
    'Quarterly review meeting',
    'Discuss integration requirements',
    'Check in on decision timeline'
};

for (Integer i = 0; i < Math.min(15, leadsToInsert.size()); i++) {
    Task t = new Task();
    t.WhoId        = leadsToInsert[i].Id;
    t.Subject      = taskSubjects[Math.mod(i, taskSubjects.size())];
    t.Status       = 'Not Started';
    // Vary due dates: overdue, today, upcoming
    Integer offset = Math.mod(i, 7) - 3;
    t.ActivityDate = today.addDays(offset);
    tasks.add(t);
}
// Add some completed tasks for activity metrics
for (Integer i = 0; i < Math.min(10, leadsToInsert.size()); i++) {
    Task t = new Task();
    t.WhoId        = leadsToInsert[i].Id;
    t.Subject      = 'Initial discovery call';
    t.Status       = 'Completed';
    t.ActivityDate = today.addDays(-1 * (i + 1));
    tasks.add(t);
}
insert tasks;
System.debug('Inserted ' + tasks.size() + ' demo tasks.');

// ── 6. Seed notes for the first 10 leads ──────────────────────────────────────
List<Note> notes = new List<Note>();
List<String> noteBodies = new List<String>{
    'Had a great intro call. They are actively evaluating CRM solutions for their development team. Budget approved for Q3.',
    'Key stakeholder is very interested in the nonprofit discount. Needs sign-off from board. Follow up after their board meeting on the 15th.',
    'Organization recently grew from 20 to 60 staff. Current spreadsheet system is breaking down. Strong pain point identified.',
    'They have a tight timeline — new fiscal year starts in 2 months. Need proposal by end of month.',
    'Concerned about data migration from their legacy system. Schedule a technical deep-dive with their IT lead.',
    'Executive director loved the demo. Sent them the ROI calculator. Waiting on internal approval.',
    'Referred by Green Future Foundation. Already familiar with our platform. Fast-track opportunity.',
    'They run 3 annual campaigns and need better donor/lead tracking. The workflow automation feature resonated strongly.',
    'Small team but high-growth. Will likely upgrade within 6 months. Keep nurturing.',
    'Received RFP this morning. Three vendors in consideration. Price sensitivity is medium-high.'
};

for (Integer i = 0; i < Math.min(10, leadsToInsert.size()); i++) {
    Note n = new Note();
    n.ParentId = leadsToInsert[i].Id;
    n.Title    = 'Discovery Notes — ' + leadsToInsert[i].Company.replace(' [Demo]', '');
    n.Body     = noteBodies[i];
    notes.add(n);
}
insert notes;
System.debug('Inserted ' + notes.size() + ' demo notes.');

// ── 7. Seed audit trail for stage progressions ────────────────────────────────
List<Lead_Audit__c> audits = new List<Lead_Audit__c>();
for (Integer i = 0; i < Math.min(20, leadsToInsert.size()); i++) {
    Lead_Audit__c a = new Lead_Audit__c();
    a.Lead__c         = leadsToInsert[i].Id;
    a.Audit_Type__c   = 'Lead Created';
    a.Message__c      = 'Lead entered pipeline at stage: ' + leadsToInsert[i].Current_Stage__c;
    a.New_Value__c    = leadsToInsert[i].Current_Stage__c;
    a.Performed_By__c = UserInfo.getUserId();
    a.Performed_On__c = Datetime.now().addDays(-1 * (Math.mod(i, 14) + 1));
    audits.add(a);
}
// Add some stage change audits for leads that are further along
for (Integer i = 5; i < Math.min(15, leadsToInsert.size()); i++) {
    Lead_Audit__c a = new Lead_Audit__c();
    a.Lead__c         = leadsToInsert[i].Id;
    a.Audit_Type__c   = 'Stage Change';
    a.Message__c      = 'Stage moved from \'Initial Inquiry\' to \'' + leadsToInsert[i].Current_Stage__c + '\'';
    a.Old_Value__c    = 'Initial Inquiry';
    a.New_Value__c    = leadsToInsert[i].Current_Stage__c;
    a.Performed_By__c = UserInfo.getUserId();
    a.Performed_On__c = Datetime.now().addDays(-1 * Math.mod(i, 7));
    audits.add(a);
}
Database.insert(audits, false);
System.debug('Inserted ' + audits.size() + ' demo audit records.');

System.debug('=== Demo seed complete. ' + leadsToInsert.size() + ' leads created. ===');
System.debug('Stages used: ' + stageKeys);
