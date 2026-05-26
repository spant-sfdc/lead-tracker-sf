/**
 * @AuraEnabled controller for the Lead Tracker LWC suite.
 * Thin delegation layer: validates inputs, calls service/pipeline layers, returns DTOs.
 * Catches all exceptions and re-throws as AuraHandledExceptions for user-friendly LWC errors.
 */
public with sharing class LeadController {

    // ── Board ─────────────────────────────────────────────────────────────────

    /**
     * Returns the full board payload for the default pipeline type.
     * cacheable=false because board state changes with every stage move.
     */
    @AuraEnabled
    public static LeadTrackerDTO.BoardData getBoardData() {
        try {
            return new PipelineService().getBoardData();
        } catch (Exception e) {
            throw new AuraHandledException('Unable to load board: ' + e.getMessage());
        }
    }

    /**
     * Returns the board payload filtered to the given pipeline type.
     */
    @AuraEnabled
    public static LeadTrackerDTO.BoardData getBoardDataByPipelineType(String pipelineType) {
        try {
            if (String.isBlank(pipelineType)) {
                throw new LeadTrackerException('pipelineType is required.');
            }
            return new PipelineService().getBoardDataByPipelineType(pipelineType);
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException('Unable to load board: ' + e.getMessage());
        }
    }

    // ── App config ────────────────────────────────────────────────────────────

    /** Returns the application config DTO. cacheable=true — config changes infrequently. */
    @AuraEnabled(cacheable=true)
    public static LeadTrackerDTO.AppConfigData getAppConfig() {
        try {
            return new PipelineService().getAppConfigData();
        } catch (Exception e) {
            throw new AuraHandledException('Unable to load config: ' + e.getMessage());
        }
    }

    // ── Stage options ─────────────────────────────────────────────────────────

    /** Returns stage option list for dropdowns. cacheable=true — CMT data is stable. */
    @AuraEnabled(cacheable=true)
    public static List<LeadTrackerDTO.StageOption> getStageOptions(String pipelineType) {
        try {
            return new PipelineService().getStageOptions(pipelineType);
        } catch (Exception e) {
            throw new AuraHandledException('Unable to load stages: ' + e.getMessage());
        }
    }

    // ── Stage movement ────────────────────────────────────────────────────────

    /**
     * Moves a single lead to the target stage.
     * Called by kanban drag-and-drop and the stage picker button.
     */
    @AuraEnabled
    public static LeadTrackerDTO.MoveResult moveLead(Id leadId, String stageKey) {
        try {
            if (leadId == null || String.isBlank(stageKey)) {
                throw new LeadTrackerException('leadId and stageKey are required.');
            }
            return new LeadService().moveLeadToStage(leadId, stageKey);
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException('Move failed: ' + e.getMessage());
        }
    }

    /**
     * Bulk-moves a list of leads to the target stage.
     * Returns one MoveResult per lead — partial failures are surfaced individually.
     */
    @AuraEnabled
    public static List<LeadTrackerDTO.MoveResult> bulkMoveLeads(List<Id> leadIds, String stageKey) {
        try {
            if (leadIds == null || leadIds.isEmpty() || String.isBlank(stageKey)) {
                throw new LeadTrackerException('leadIds and stageKey are required.');
            }
            return new LeadService().bulkMoveLeadsToStage(leadIds, stageKey);
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException('Bulk move failed: ' + e.getMessage());
        }
    }

    // ── Engagement score ──────────────────────────────────────────────────────

    /** Updates the engagement score for a single lead and recomputes health. */
    @AuraEnabled
    public static void updateEngagementScore(Id leadId, Integer score) {
        try {
            if (leadId == null || score == null) {
                throw new LeadTrackerException('leadId and score are required.');
            }
            new LeadService().updateEngagementScore(leadId, score);
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException('Score update failed: ' + e.getMessage());
        }
    }

    // ── Stale flag ────────────────────────────────────────────────────────────

    /**
     * Sets or clears the Is_Stale__c flag on a single lead.
     * Called by the kanban quick-action menu.
     */
    @AuraEnabled
    public static void setLeadStale(Id leadId, Boolean isStale) {
        try {
            if (leadId == null) throw new LeadTrackerException('leadId is required.');
            Lead l = new Lead(Id = leadId, Is_Stale__c = isStale);
            update l;
            Lead_Audit__c audit = isStale
                ? LeadAuditService.buildStaleRecord(leadId)
                : LeadAuditService.buildStaleClearedRecord(leadId);
            LeadAuditService.bulkLog(new List<Lead_Audit__c>{ audit });
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException('Stale update failed: ' + e.getMessage());
        }
    }

    // ── Timeline ──────────────────────────────────────────────────────────────

    /** Returns the audit timeline for a single lead. cacheable=false — audit grows continuously. */
    @AuraEnabled
    public static List<LeadTrackerDTO.AuditEntry> getLeadTimeline(Id leadId) {
        try {
            if (leadId == null) {
                throw new LeadTrackerException('leadId is required.');
            }
            return LeadAuditService.getTimeline(leadId);
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException('Unable to load timeline: ' + e.getMessage());
        }
    }

    /** Returns recent activity across all leads for the global feed. */
    @AuraEnabled
    public static List<LeadTrackerDTO.AuditEntry> getRecentActivity(Integer maxRecords) {
        try {
            return LeadAuditService.getRecentActivity(maxRecords);
        } catch (Exception e) {
            throw new AuraHandledException('Unable to load activity: ' + e.getMessage());
        }
    }

    // ── Drawer: Tasks / Notes / Files ─────────────────────────────────────────

    /** Returns Task records for the lead activity panel. */
    @AuraEnabled
    public static List<Task> getLeadTasks(Id leadId) {
        try {
            if (leadId == null) throw new LeadTrackerException('leadId is required.');
            return [SELECT Id, Subject, Description, Status, ActivityDate, Type,
                           CreatedDate, Owner.Name
                    FROM Task WHERE WhoId = :leadId WITH USER_MODE
                    ORDER BY CreatedDate DESC LIMIT 50];
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException('Unable to load tasks: ' + e.getMessage());
        }
    }

    /** Creates a completed Task (activity log) for the lead. Returns new Task Id. */
    @AuraEnabled
    public static Id logActivity(Id leadId, String subject, String description,
                                  String type, String activityDate) {
        try {
            if (leadId == null || String.isBlank(subject)) {
                throw new LeadTrackerException('leadId and subject are required.');
            }
            Task t = new Task(
                WhoId       = leadId,
                Subject     = subject,
                Description = description,
                Status      = 'Completed',
                Type        = String.isBlank(type) ? 'Other' : type
            );
            if (String.isNotBlank(activityDate)) {
                t.ActivityDate = Date.valueOf(activityDate);
            }
            insert t;
            return t.Id;
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException('Unable to log activity: ' + e.getMessage());
        }
    }

    /** Returns Note records attached to the lead. */
    @AuraEnabled
    public static List<Note> getLeadNotes(Id leadId) {
        try {
            if (leadId == null) throw new LeadTrackerException('leadId is required.');
            return [SELECT Id, Title, Body, CreatedDate, Owner.Name
                    FROM Note WHERE ParentId = :leadId WITH USER_MODE
                    ORDER BY CreatedDate DESC LIMIT 50];
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException('Unable to load notes: ' + e.getMessage());
        }
    }

    /** Creates a Note attached to the lead. Returns new Note Id. */
    @AuraEnabled
    public static Id addNote(Id leadId, String title, String body) {
        try {
            if (leadId == null || String.isBlank(body)) {
                throw new LeadTrackerException('leadId and body are required.');
            }
            Note n = new Note(
                ParentId = leadId,
                Title    = String.isBlank(title) ? 'Note' : title,
                Body     = body
            );
            insert n;
            return n.Id;
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException('Unable to add note: ' + e.getMessage());
        }
    }

    /** Returns ContentDocumentLink records for the lead (file attachments). */
    @AuraEnabled
    public static List<ContentDocumentLink> getLeadFiles(Id leadId) {
        try {
            if (leadId == null) throw new LeadTrackerException('leadId is required.');
            return [SELECT ContentDocument.Id, ContentDocument.Title,
                           ContentDocument.FileExtension, ContentDocument.ContentSize,
                           ContentDocument.CreatedDate, ContentDocument.Owner.Name
                    FROM ContentDocumentLink WHERE LinkedEntityId = :leadId WITH USER_MODE
                    ORDER BY ContentDocument.CreatedDate DESC LIMIT 50];
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException('Unable to load files: ' + e.getMessage());
        }
    }
}
