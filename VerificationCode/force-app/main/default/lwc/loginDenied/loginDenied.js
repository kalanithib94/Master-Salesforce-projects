import { LightningElement } from 'lwc';

/**
 * loginDenied LWC
 *
 * Used inside the VerificationCodeLoginFlow screen for the MAX_ATTEMPTS_EXCEEDED branch.
 * As soon as the component is connected to the DOM, it navigates the top-level window
 * to login.salesforce.com, which abandons the in-progress Login Flow before Salesforce
 * can grant the user a session.
 *
 * window.top is used (instead of window) because inside the Login Flow, the flow UI is
 * rendered in an iframe and we need to break out to the top-level browser context.
 */
export default class LoginDenied extends LightningElement {
    connectedCallback() {
        // Small timeout gives the browser a moment to render the message before redirect,
        // so the user sees brief feedback rather than an abrupt blank screen.
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            // Navigate the entire top-level browser context away. This exits the Login
            // Flow without completing it, so no Salesforce session is established.
            window.top.location.href = 'https://login.salesforce.com';
        }, 2000);
    }
}
