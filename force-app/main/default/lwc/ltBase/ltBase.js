// Shared constants and utility functions for Lead Tracker LWC components.
// Import named exports into other components: import { formatCurrency } from 'c/ltBase'

export const LT_DEFAULT_ICON = 'standard:lead';
export const LT_DEFAULT_COLOR = '#0176D3';
export const LT_DATE_FORMAT = { year: 'numeric', month: 'short', day: 'numeric' };

export const formatCurrency = (value) => {
    if (value == null || value === '') return '';
    return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0
    }).format(value);
};

export const formatDate = (dateString) => {
    if (!dateString) return '';
    return new Date(dateString).toLocaleDateString('en-US', LT_DATE_FORMAT);
};

export const truncate = (str, maxLength = 40) => {
    if (!str) return '';
    return str.length > maxLength ? str.substring(0, maxLength) + '...' : str;
};

export const debounce = (fn, delay = 300) => {
    let timer;
    return (...args) => {
        clearTimeout(timer);
        timer = setTimeout(() => fn(...args), delay);
    };
};
