// Lead Tracker - Anonymous Apex utility scripts
// Run these in Developer Console > Execute Anonymous or via:
//   sf apex run --file scripts/apex/anonymousApex.apex --target-org sf-dev-edition-partner-org

// --- Verify pipeline stages are loaded ---
List<LeadTracker_Pipeline_Stage__mdt> stages = LeadTrackerSelector.getActivePipelineStages();
System.debug('Pipeline Stages: ' + stages.size());
for (LeadTracker_Pipeline_Stage__mdt s : stages) {
    System.debug(s.Sort_Order__c + ': ' + s.Stage_Name__c + ' [' + s.Color_Hex__c + ']');
}

// --- Verify app config ---
LeadTracker_App_Config__mdt config = LeadTrackerSelector.getAppConfig();
System.debug('App Config: ' + JSON.serialize(config));

// --- Create sample leads for testing ---
// List<Lead> testLeads = new List<Lead>{
//     new Lead(FirstName='Alice', LastName='Johnson', Company='Acme Corp', Status='Open - Not Contacted', Email='alice@acme.com'),
//     new Lead(FirstName='Bob', LastName='Smith', Company='Globex Inc', Status='Working - Contacted', Email='bob@globex.com'),
//     new Lead(FirstName='Carol', LastName='White', Company='Initech', Status='Open - Not Contacted', Email='carol@initech.com')
// };
// insert testLeads;
// System.debug('Inserted ' + testLeads.size() + ' test leads');
