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

    // ── Home Workspace ────────────────────────────────────────────────────────

    /**
     * Returns top-10 leads that need immediate attention:
     * stale leads, critical health, or At Risk with overdue follow-ups.
     */
    @AuraEnabled
    public static List<LeadTrackerDTO.LeadCard> getPriorityLeads() {
        try {
            List<Lead> leads = [
                SELECT Id, FirstName, LastName, Company, Current_Stage__c, Lead_Health__c,
                       Engagement_Score__c, Is_Stale__c, Next_Follow_Up__c,
                       Last_Activity_Date__c, Owner.Name, Pipeline_Type__c, Email, Phone
                FROM   Lead
                WHERE  IsConverted = false
                AND    (Is_Stale__c = true
                        OR Lead_Health__c = 'Critical'
                        OR (Lead_Health__c = 'At Risk' AND Next_Follow_Up__c < TODAY))
                WITH   USER_MODE
                ORDER  BY Next_Follow_Up__c ASC NULLS LAST, Is_Stale__c DESC
                LIMIT  10
            ];
            List<LeadTrackerDTO.LeadCard> result = new List<LeadTrackerDTO.LeadCard>();
            for (Lead l : leads) {
                LeadTrackerDTO.LeadCard card = new LeadTrackerDTO.LeadCard();
                card.leadId           = l.Id;
                card.name             = (l.FirstName != null ? l.FirstName + ' ' : '') + l.LastName;
                card.company          = l.Company;
                card.email            = l.Email;
                card.phone            = l.Phone;
                card.currentStage     = l.Current_Stage__c;
                card.pipelineType     = l.Pipeline_Type__c;
                card.leadHealth       = l.Lead_Health__c;
                card.engagementScore  = l.Engagement_Score__c != null
                    ? Integer.valueOf(l.Engagement_Score__c) : 0;
                card.isStale          = l.Is_Stale__c == true;
                card.nextFollowUp     = l.Next_Follow_Up__c != null
                    ? String.valueOf(l.Next_Follow_Up__c) : null;
                card.lastActivityDate = l.Last_Activity_Date__c != null
                    ? String.valueOf(l.Last_Activity_Date__c) : null;
                card.ownerName        = l.Owner != null ? l.Owner.Name : null;
                result.add(card);
            }
            return result;
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException('Unable to load priority leads: ' + e.getMessage());
        }
    }

    /**
     * Returns open tasks due within the next 7 days plus all overdue tasks.
     * Used by the home workspace upcoming tasks panel.
     */
    @AuraEnabled
    public static List<LeadTrackerDTO.UpcomingTaskItem> getUpcomingTasks() {
        try {
            Date today   = Date.today();
            Date cutoff  = today.addDays(7);
            List<Task> tasks = [
                SELECT Id, Subject, Type, Status, ActivityDate, WhoId, Who.Name
                FROM   Task
                WHERE  Status != 'Completed'
                AND    WhoId  != null
                AND    ActivityDate <= :cutoff
                WITH   USER_MODE
                ORDER  BY ActivityDate ASC NULLS LAST
                LIMIT  30
            ];
            List<LeadTrackerDTO.UpcomingTaskItem> result = new List<LeadTrackerDTO.UpcomingTaskItem>();
            for (Task t : tasks) {
                LeadTrackerDTO.UpcomingTaskItem item = new LeadTrackerDTO.UpcomingTaskItem();
                item.taskId       = t.Id;
                item.leadId       = t.WhoId;
                item.leadName     = t.Who != null ? t.Who.Name : null;
                item.subject      = t.Subject;
                item.type         = t.Type;
                item.activityDate = t.ActivityDate != null ? String.valueOf(t.ActivityDate) : null;
                item.isOverdue    = t.ActivityDate != null && t.ActivityDate < today;
                item.isDueToday   = t.ActivityDate != null && t.ActivityDate == today;
                result.add(item);
            }
            return result;
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException('Unable to load upcoming tasks: ' + e.getMessage());
        }
    }

    /** Marks a single Task as Completed. Called by the home workspace task panel. */
    @AuraEnabled
    public static void completeTask(Id taskId) {
        try {
            if (taskId == null) throw new LeadTrackerException('taskId is required.');
            update new Task(Id = taskId, Status = 'Completed');
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException('Unable to complete task: ' + e.getMessage());
        }
    }

    /**
     * Returns recent audit entries with lead name context for the global activity feed.
     * Distinct from getRecentActivity — includes Lead relationship query for display names.
     */
    @AuraEnabled
    public static List<LeadTrackerDTO.AuditEntry> getActivityFeed(Integer maxRecords) {
        try {
            Integer lim = (maxRecords != null && maxRecords > 0 && maxRecords <= 100) ? maxRecords : 30;
            List<Lead_Audit__c> records = [
                SELECT Id, Audit_Type__c, Message__c, Old_Value__c, New_Value__c,
                       Performed_By__c, Performed_On__c, Lead__c,
                       Lead__r.FirstName, Lead__r.LastName
                FROM   Lead_Audit__c
                WITH   USER_MODE
                ORDER  BY Performed_On__c DESC
                LIMIT  :lim
            ];
            List<LeadTrackerDTO.AuditEntry> entries = new List<LeadTrackerDTO.AuditEntry>();
            for (Lead_Audit__c a : records) {
                LeadTrackerDTO.AuditEntry e = new LeadTrackerDTO.AuditEntry();
                e.auditId     = a.Id;
                e.auditType   = a.Audit_Type__c;
                e.message     = a.Message__c;
                e.oldValue    = a.Old_Value__c;
                e.newValue    = a.New_Value__c;
                e.performedBy = a.Performed_By__c;
                e.performedOn = a.Performed_On__c != null ? String.valueOf(a.Performed_On__c) : null;
                if (a.Lead__c != null) {
                    e.leadId   = a.Lead__c;
                    String fn  = a.Lead__r?.FirstName;
                    String ln  = a.Lead__r?.LastName;
                    e.leadName = (String.isNotBlank(fn) ? fn + ' ' : '') + (ln != null ? ln : '');
                }
                entries.add(e);
            }
            return entries;
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException('Unable to load activity feed: ' + e.getMessage());
        }
    }

    // ── Dashboard ─────────────────────────────────────────────────────────────

    /**
     * Returns aggregated metrics for the analytics dashboard.
     * Uses 3 aggregate + 5 scalar SOQL queries; CMT lookups via selector cache.
     */
    @AuraEnabled
    public static LeadTrackerDTO.DashboardData getDashboardData() {
        try {
            PipelineStageSelector stageSelector = new PipelineStageSelector();

            // 1. Leads by stage + health in one aggregate query
            List<AggregateResult> stageHealthRows = [
                SELECT Current_Stage__c stageKey, Lead_Health__c health, COUNT(Id) cnt
                FROM   Lead
                WHERE  IsConverted = false
                WITH   USER_MODE
                GROUP BY Current_Stage__c, Lead_Health__c
            ];

            // 2. Leads by pipeline type
            List<AggregateResult> pipelineRows = [
                SELECT Pipeline_Type__c pipelineType, COUNT(Id) cnt
                FROM   Lead
                WHERE  IsConverted = false
                WITH   USER_MODE
                GROUP BY Pipeline_Type__c
            ];

            // 3. Average engagement score
            List<AggregateResult> scoreRows = [
                SELECT AVG(Engagement_Score__c) avgScore
                FROM   Lead
                WHERE  IsConverted = false AND Engagement_Score__c != null
                WITH   USER_MODE
            ];

            // 4. Scalar counts
            Integer convertedLeads    = [SELECT COUNT() FROM Lead WHERE IsConverted = true WITH USER_MODE];
            Integer staleLeads        = [SELECT COUNT() FROM Lead WHERE Is_Stale__c = true AND IsConverted = false WITH USER_MODE];
            Integer overdueFollowUps  = [SELECT COUNT() FROM Lead WHERE Next_Follow_Up__c < TODAY AND IsConverted = false WITH USER_MODE];
            Date    nextWeek          = Date.today().addDays(7);
            Integer upcomingFollowUps = [SELECT COUNT() FROM Lead WHERE Next_Follow_Up__c >= TODAY AND Next_Follow_Up__c <= :nextWeek AND IsConverted = false WITH USER_MODE];
            Integer activitiesThisWeek = [SELECT COUNT() FROM Task WHERE Status = 'Completed' AND ActivityDate = THIS_WEEK WITH USER_MODE];

            // 5. CMT stage map — labels, colors, ordering (no SOQL in loops)
            Map<String, Pipeline_Stage__mdt> stageMap    = stageSelector.getActiveStageMapByKey();
            List<Pipeline_Stage__mdt>        allStages   = stageSelector.getAllActiveStages();

            // 6. Accumulate per-stage metrics and health totals
            Map<String, LeadTrackerDTO.StageMetric> smMap = new Map<String, LeadTrackerDTO.StageMetric>();
            Integer totalLeads = 0, healthyLeads = 0, atRiskLeads = 0, criticalLeads = 0;

            for (AggregateResult row : stageHealthRows) {
                String  sk     = (String)  row.get('stageKey');
                String  health = (String)  row.get('health');
                Integer cnt    = (Integer) row.get('cnt');
                if (sk == null) sk = 'Unassigned';
                totalLeads += cnt;

                if (!smMap.containsKey(sk)) {
                    LeadTrackerDTO.StageMetric sm = new LeadTrackerDTO.StageMetric();
                    sm.stageKey   = sk;
                    Pipeline_Stage__mdt mdt = stageMap.get(sk);
                    sm.stageLabel = mdt != null ? mdt.Stage_Label__c : sk;
                    sm.color      = mdt != null && String.isNotBlank(mdt.Color__c) ? mdt.Color__c : '#706E6B';
                    sm.sequence   = mdt != null && mdt.Sequence__c != null ? Integer.valueOf(mdt.Sequence__c) : 999;
                    sm.count      = 0;
                    smMap.put(sk, sm);
                }
                smMap.get(sk).count += cnt;

                if      ('Healthy'.equalsIgnoreCase(health))  healthyLeads  += cnt;
                else if ('At Risk'.equalsIgnoreCase(health))  atRiskLeads   += cnt;
                else if ('Critical'.equalsIgnoreCase(health)) criticalLeads += cnt;
            }

            // Compute percentages, preserving CMT stage order
            for (LeadTrackerDTO.StageMetric sm : smMap.values()) {
                sm.percentage = totalLeads > 0
                    ? (Decimal.valueOf(sm.count) / totalLeads * 100).setScale(1) : 0;
            }
            List<LeadTrackerDTO.StageMetric> stageMetrics = new List<LeadTrackerDTO.StageMetric>();
            for (Pipeline_Stage__mdt mdt : allStages) {
                if (smMap.containsKey(mdt.Stage_Key__c)) {
                    stageMetrics.add(smMap.get(mdt.Stage_Key__c));
                }
            }
            for (String sk : smMap.keySet()) {
                if (!stageMap.containsKey(sk)) {
                    stageMetrics.add(smMap.get(sk));
                }
            }

            // 7. Pipeline metrics
            List<LeadTrackerDTO.PipelineMetric> pipelineMetrics = new List<LeadTrackerDTO.PipelineMetric>();
            for (AggregateResult row : pipelineRows) {
                LeadTrackerDTO.PipelineMetric pm = new LeadTrackerDTO.PipelineMetric();
                String pt = (String) row.get('pipelineType');
                pm.pipelineType = String.isBlank(pt) ? 'Unassigned' : pt;
                pm.count        = (Integer) row.get('cnt');
                pm.percentage   = totalLeads > 0
                    ? (Decimal.valueOf(pm.count) / totalLeads * 100).setScale(1) : 0;
                pipelineMetrics.add(pm);
            }

            // 8. Average engagement score
            Decimal avgScore = 0;
            if (!scoreRows.isEmpty() && scoreRows[0].get('avgScore') != null) {
                avgScore = ((Decimal) scoreRows[0].get('avgScore')).setScale(1);
            }

            // 9. Assemble DTO
            LeadTrackerDTO.DashboardData data = new LeadTrackerDTO.DashboardData();
            data.totalLeads         = totalLeads;
            data.openLeads          = totalLeads;
            data.convertedLeads     = convertedLeads;
            data.staleLeads         = staleLeads;
            data.healthyLeads       = healthyLeads;
            data.atRiskLeads        = atRiskLeads;
            data.criticalLeads      = criticalLeads;
            data.overdueFollowUps   = overdueFollowUps;
            data.upcomingFollowUps  = upcomingFollowUps;
            data.activitiesThisWeek = activitiesThisWeek;
            data.avgEngagementScore = avgScore;
            data.conversionRate     = (convertedLeads + totalLeads) > 0
                ? (Decimal.valueOf(convertedLeads) / (convertedLeads + totalLeads) * 100).setScale(1)
                : 0;
            data.stageMetrics       = stageMetrics;
            data.pipelineMetrics    = pipelineMetrics;
            data.refreshedAt        = String.valueOf(System.now());
            return data;
        } catch (Exception e) {
            throw new AuraHandledException('Unable to load dashboard: ' + e.getMessage());
        }
    }
}
