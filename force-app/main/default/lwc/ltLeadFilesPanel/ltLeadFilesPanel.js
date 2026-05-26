import { LightningElement, api, track } from 'lwc';
import { formatDate } from 'c/ltBase';
import getLeadFiles from '@salesforce/apex/LeadController.getLeadFiles';

const EXT_CONFIG = {
    pdf:  { icon: 'doctype:pdf',   color: '#C23934' },
    doc:  { icon: 'doctype:word',  color: '#0176D3' },
    docx: { icon: 'doctype:word',  color: '#0176D3' },
    xls:  { icon: 'doctype:excel', color: '#00875A' },
    xlsx: { icon: 'doctype:excel', color: '#00875A' },
    ppt:  { icon: 'doctype:ppt',   color: '#B75000' },
    pptx: { icon: 'doctype:ppt',   color: '#B75000' },
    jpg:  { icon: 'doctype:image', color: '#5867E8' },
    jpeg: { icon: 'doctype:image', color: '#5867E8' },
    png:  { icon: 'doctype:image', color: '#5867E8' },
    csv:  { icon: 'doctype:csv',   color: '#00875A' }
};
const DEFAULT_EXT = { icon: 'doctype:attachment', color: '#706E6B' };

export default class LtLeadFilesPanel extends LightningElement {
    @track files = [];
    @track isLoading = false;
    @track errorMessage = '';

    acceptedFormats = ['.pdf', '.doc', '.docx', '.xls', '.xlsx',
                       '.ppt', '.pptx', '.png', '.jpg', '.jpeg', '.csv', '.txt'];

    _leadId;

    @api
    get leadId() { return this._leadId; }
    set leadId(val) {
        this._leadId = val;
        if (val) this.loadFiles();
    }

    // ── Computed ──────────────────────────────────────────────────────────────

    get hasError()  { return !this.isLoading && !!this.errorMessage; }
    get isEmpty()   { return !this.isLoading && !this.errorMessage && this.files.length === 0; }
    get fileCount() { return this.files.length; }

    // ── Data ──────────────────────────────────────────────────────────────────

    async loadFiles() {
        this.isLoading = true;
        this.errorMessage = '';
        try {
            const raw = await getLeadFiles({ leadId: this._leadId });
            this.files = (raw || []).map(link => {
                const doc = link.ContentDocument;
                const ext = (doc.FileExtension || '').toLowerCase();
                const cfg = EXT_CONFIG[ext] || DEFAULT_EXT;
                return {
                    id:            doc.Id,
                    title:         doc.Title,
                    ext:           ext.toUpperCase(),
                    icon:          cfg.icon,
                    iconStyle:     `background-color: ${cfg.color}1A; color: ${cfg.color}`,
                    formattedSize: this._formatSize(doc.ContentSize),
                    ownerName:     doc.Owner?.Name || '',
                    relativeTime:  this._relativeTime(doc.CreatedDate),
                    downloadUrl:   `/sfc/servlet.shepherd/document/download/${doc.Id}`
                };
            });
        } catch (e) {
            this.errorMessage = e.body?.message || 'Failed to load files.';
        } finally {
            this.isLoading = false;
        }
    }

    handleUploadFinished() {
        this.loadFiles();
    }

    // ── Utility ───────────────────────────────────────────────────────────────

    _formatSize(bytes) {
        if (!bytes) return '—';
        if (bytes < 1024)    return `${bytes} B`;
        if (bytes < 1048576) return `${(bytes / 1024).toFixed(1)} KB`;
        return `${(bytes / 1048576).toFixed(1)} MB`;
    }

    _relativeTime(dateString) {
        if (!dateString) return '';
        const ms   = Date.now() - new Date(dateString).getTime();
        const mins = Math.floor(ms / 60000);
        if (mins < 1)  return 'just now';
        if (mins < 60) return `${mins}m ago`;
        const hrs = Math.floor(mins / 60);
        if (hrs  < 24) return `${hrs}h ago`;
        const days = Math.floor(hrs / 24);
        if (days < 7)  return `${days}d ago`;
        return formatDate(dateString);
    }
}
