import { LightningElement, track } from 'lwc';
import { debounce } from 'c/ltBase';

const HEALTH_VALUES = ['Healthy', 'At Risk', 'Critical'];
const HEALTH_COLORS = {
    'Healthy':  '#00875A',
    'At Risk':  '#B75000',
    'Critical': '#C23934'
};

export default class LtFilterSidebar extends LightningElement {
    @track _searchTerm = '';
    @track _healthFilter = [];
    @track _showStaleOnly = false;

    connectedCallback() {
        this._debouncedSearch = debounce((term) => {
            this._searchTerm = term;
            this._emitFilterChange();
        }, 300);
    }

    // ── Computed ──────────────────────────────────────────────────────────────

    get healthPills() {
        return HEALTH_VALUES.map(h => {
            const active = this._healthFilter.includes(h);
            const key = h.toLowerCase().replace(' ', '-');
            return {
                id: h,
                label: h,
                active: active,
                cssClass: `fs-pill fs-pill--${key}${active ? ' fs-pill--active' : ''}`,
                dotStyle: `background-color: ${HEALTH_COLORS[h] || '#706E6B'}`
            };
        });
    }

    get hasActiveFilters() {
        return this._searchTerm || this._healthFilter.length > 0 || this._showStaleOnly;
    }

    // ── Handlers ──────────────────────────────────────────────────────────────

    handleSearchInput(event) {
        this._debouncedSearch(event.target.value);
    }

    handleHealthClick(event) {
        const health = event.currentTarget.dataset.health;
        if (this._healthFilter.includes(health)) {
            this._healthFilter = this._healthFilter.filter(h => h !== health);
        } else {
            this._healthFilter = [...this._healthFilter, health];
        }
        this._emitFilterChange();
    }

    handleStaleToggle(event) {
        this._showStaleOnly = event.target.checked;
        this._emitFilterChange();
    }

    handleClearFilters() {
        this._searchTerm = '';
        this._healthFilter = [];
        this._showStaleOnly = false;
        // Reset search input value
        const input = this.template.querySelector('.fs-search-input');
        if (input) input.value = '';
        // Reset checkbox
        const checkbox = this.template.querySelector('.fs-checkbox');
        if (checkbox) checkbox.checked = false;
        this._emitFilterChange();
    }

    // ── Private ───────────────────────────────────────────────────────────────

    _emitFilterChange() {
        this.dispatchEvent(
            new CustomEvent('filterchange', {
                bubbles: true,
                composed: true,
                detail: {
                    searchTerm: this._searchTerm,
                    healthFilter: [...this._healthFilter],
                    showStaleOnly: this._showStaleOnly
                }
            })
        );
    }
}
