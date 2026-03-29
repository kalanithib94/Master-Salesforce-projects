import { LightningElement, track } from 'lwc';
import createSupportCase  from '@salesforce/apex/CaseResolutionController.createSupportCase';
import getRecommendation  from '@salesforce/apex/CaseResolutionController.getRecommendation';
import resolveCase        from '@salesforce/apex/CaseResolutionController.resolveCase';

const STATE = {
    INPUT:          'input',
    LOADING:        'loading',
    RECOMMENDATION: 'recommendation',
    RESOLVING:      'resolving',
    RESOLVED:       'resolved',
    CASE_CREATED:   'caseCreated'
};

const VISIBLE = 'cra-state';
const HIDDEN  = 'cra-state cra-state--hidden';

// Polling: check every 2.5 s, give up after 30 s (12 attempts)
const POLL_INTERVAL_MS = 2500;
const POLL_MAX_ATTEMPTS = 12;

export default class CaseResolutionAssistant extends LightningElement {

    // ─── Form Fields ──────────────────────────────────────────────────────────
    @track firstName = '';
    @track lastName  = '';
    @track email     = '';
    @track product   = '';
    @track subject   = '';

    // ─── Result ───────────────────────────────────────────────────────────────
    @track recommendation = '';
    @track caseId         = '';
    @track caseNumber     = '';
    @track errorMessage   = '';
    @track currentState   = STATE.INPUT;

    // ─── CSS State Classes ───────────────────────────────────────────────────

    get inputStateClass()          { return this._stateClass(STATE.INPUT); }
    get loadingStateClass()        { return this._stateClass(STATE.LOADING); }
    get recommendationStateClass() { return this._stateClass(STATE.RECOMMENDATION); }
    get resolvingStateClass()      { return this._stateClass(STATE.RESOLVING); }
    get resolvedStateClass()       { return this._stateClass(STATE.RESOLVED); }
    get caseCreatedStateClass()    { return this._stateClass(STATE.CASE_CREATED); }

    get errorStateClass() {
        return this.errorMessage ? VISIBLE : HIDDEN;
    }

    _stateClass(state) {
        return this.currentState === state ? VISIBLE : HIDDEN;
    }

    // ─── Validation ───────────────────────────────────────────────────────────

    get isSubmitDisabled() {
        return (
            !this.firstName.trim() ||
            !this.lastName.trim()  ||
            !this.email.trim()     ||
            !this.product          ||
            !this.subject.trim()
        );
    }

    // ─── Form Handlers ───────────────────────────────────────────────────────

    get productOptions() {
        return [
            { label: 'RentPayment', value: 'RentPayment' },
            { label: 'Property Management X (PMX)', value: 'Property Management X (PMX)' }
        ];
    }

    handleFirstNameChange(event) { this.firstName = event.target.value; this._clearError(); }
    handleLastNameChange(event)  { this.lastName  = event.target.value; this._clearError(); }
    handleEmailChange(event)     { this.email     = event.target.value; this._clearError(); }
    handleProductChange(event)   { this.product   = event.detail.value; this._clearError(); }
    handleSubjectChange(event)   { this.subject   = event.target.value; this._clearError(); }

    handleCancel() { this.handleReset(); }

    // ─── Submit: create case then poll for AI recommendation ─────────────────

    async handleSubmit() {
        if (this.isSubmitDisabled) return;

        this.currentState = STATE.LOADING;
        this.errorMessage = '';

        try {
            // Step 1: Create case immediately (fires Record-Triggered Flow async)
            const result = await createSupportCase({
                firstName : this.firstName.trim(),
                lastName  : this.lastName.trim(),
                email     : this.email.trim(),
                category  : this.product,
                subject   : this.subject.trim()
            });

            this.caseId     = result.caseId;
            this.caseNumber = result.caseNumber;

            // Step 2: Poll Case.Description until RTF writes the AI response
            const rec = await this._pollForRecommendation();
            this.recommendation = rec;
            this.currentState   = STATE.RECOMMENDATION;

        } catch (error) {
            this.errorMessage = this._extractError(
                error,
                'Unable to submit your request. Please try again.'
            );
            this.currentState = STATE.INPUT;
        }
    }

    // ─── Polling ─────────────────────────────────────────────────────────────

    async _pollForRecommendation() {
        for (let i = 0; i < POLL_MAX_ATTEMPTS; i++) {
            await this._sleep(POLL_INTERVAL_MS);
            try {
                const rec = await getRecommendation({ caseId: this.caseId });
                if (rec) return rec;
            } catch (_) {
                // Transient error — keep polling
            }
        }
        // Timed out (30 s): show graceful fallback; case is still open
        return (
            'Our AI is still processing your request. ' +
            'A support agent will review your case and reach out to you shortly.'
        );
    }

    _sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    // ─── Yes: close the case ─────────────────────────────────────────────────

    async handleYes() {
        this.currentState = STATE.RESOLVING;
        try {
            await resolveCase({ caseId: this.caseId });
        } catch (err) {
            // Surface the error but still transition — case closure failure
            // should not block the user from seeing the resolved screen.
            this.errorMessage = this._extractError(
                err,
                'Case could not be closed automatically, but your issue is noted.'
            );
        }
        this.currentState = STATE.RESOLVED;
    }

    // ─── No: keep case open, show case number ────────────────────────────────

    handleNo() {
        this.currentState = STATE.CASE_CREATED;
    }

    // ─── Reset ───────────────────────────────────────────────────────────────

    handleReset() {
        this.firstName      = '';
        this.lastName       = '';
        this.email          = '';
        this.product        = '';
        this.subject        = '';
        this.recommendation = '';
        this.caseId         = '';
        this.caseNumber     = '';
        this.errorMessage   = '';
        this.currentState   = STATE.INPUT;
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    _clearError() { if (this.errorMessage) this.errorMessage = ''; }

    _extractError(error, fallback) {
        if (error && error.body && error.body.message) return error.body.message;
        if (error && error.message) return error.message;
        return fallback;
    }
}
