import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createSession from '@salesforce/apex/AgentforceController.createSession';
import sendMessage from '@salesforce/apex/AgentforceController.sendMessage';
import endSession from '@salesforce/apex/AgentforceController.endSession';
import USER_ID from '@salesforce/user/Id';

export default class AgentforceChat extends LightningElement {
    userId = USER_ID;

    @track sessionId = null;
    @track messages = [];
    @track inputText = '';
    @track isLoading = false;
    @track isOnline = false;

    messageCounter = 0;

    get statusClass() {
        return this.isOnline ? 'agent-status online' : 'agent-status offline';
    }

    get statusLabel() {
        return this.isOnline ? 'Online' : 'Offline';
    }

    get isSendDisabled() {
        return this.isLoading || !this.inputText.trim();
    }

    async handleStartSession() {
        this.isLoading = true;
        try {
            this.sessionId = await createSession();
            this.isOnline = true;
            this.addAgentMessage('Olá! Sou o Agente de Suporte. Como posso te ajudar?');
        } catch (error) {
            this.showError('Erro ao iniciar sessão: ' + (error.body?.message || error.message));
        } finally {
            this.isLoading = false;
        }
    }

    async handleSend() {
        const text = this.inputText.trim();
        if (!text || this.isLoading) return;

        this.inputText = '';
        const textarea = this.template.querySelector('textarea');
        if (textarea) textarea.value = '';
        this.addUserMessage(text);
        this.isLoading = true;

        try {
            const response = await sendMessage({ sessionId: this.sessionId, messageText: text });
            this.addAgentMessage(response);
        } catch (error) {
            this.addAgentMessage('Desculpe, ocorreu um erro. Tente novamente.');
            this.showError('Erro ao enviar mensagem: ' + (error.body?.message || error.message));
        } finally {
            this.isLoading = false;
            this.scrollToBottom();
        }
    }

    async handleEndSession() {
        if (this.sessionId) {
            await endSession({ sessionId: this.sessionId });
        }
        this.sessionId = null;
        this.messages = [];
        this.isOnline = false;
        this.inputText = '';
    }

    handleInput(event) {
        this.inputText = event.target.value;
    }

    handleKeyDown(event) {
        if (event.key === 'Enter' && !event.shiftKey) {
            event.preventDefault();
            this.handleSend();
        }
    }

    addUserMessage(text) {
        this.messages = [...this.messages, {
            id: ++this.messageCounter,
            text,
            isAgent: false,
            wrapperClass: 'msg-wrapper user',
            bubbleClass: 'msg-bubble user',
            time: this.getCurrentTime()
        }];
        this.scrollToBottom();
    }

    addAgentMessage(text) {
        this.messages = [...this.messages, {
            id: ++this.messageCounter,
            text,
            isAgent: true,
            wrapperClass: 'msg-wrapper agent',
            bubbleClass: 'msg-bubble agent',
            time: this.getCurrentTime()
        }];
        this.scrollToBottom();
    }

    getCurrentTime() {
        return new Date().toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
    }

    scrollToBottom() {
        setTimeout(() => {
            const container = this.template.querySelector('.chat-messages');
            if (container) container.scrollTop = container.scrollHeight;
        }, 50);
    }

    showError(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Erro',
            message,
            variant: 'error'
        }));
    }
}