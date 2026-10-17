import { LightningElement, api, wire, track } from 'lwc';

import {
    subscribe,
    unsubscribe,
    onError,
    setDebugFlag,
    isEmpEnabled,
} from 'lightning/empApi';



export default class RecordPageUpdater extends LightningElement {
  @api watchedField;
  @api recordId;
  @api objectApiName;
  field = ''
  currentId = ''
  channelName = '/data/OpportunityChangeEvent';
  subscription = {};

  // Tracks changes to channelName text field
  handleChannelName(event) {
      this.channelName = event.target.value;
  }

  // Initializes the component
  connectedCallback() {
      // Register error listener
      if(this.objectApiName.endsWith('__c')){
        let objName
        objName = this.objectApiName.slice(0, -1);
        this.channelName = '/data/' + objName + 'ChangeEvent'
      }
      else{
        this.channelName = '/data/' + this.objectApiName + 'ChangeEvent'
      }
      
      this.registerErrorListener();
      this.handleSubscribe();
  }

  // Handles subscribe button click
  handleSubscribe() {
      // Callback invoked whenever a new event message is received
      const messageCallback = function (response) {
          //console.log('New message received: ', JSON.stringify(response));

          console.log(response.data.payload.ChangeEventHeader.changedFields)
          console.log(response.data.payload.ChangeEventHeader.recordIds)

          if(response.data.payload.ChangeEventHeader.changedFields.includes(this.watchedField) && response.data.payload.ChangeEventHeader.recordIds.includes(this.recordId)){
            eval("$A.get('e.force:refreshView').fire();")
          }
          // Response contains the payload of the new message received
      };

      // Invoke subscribe method of empApi. Pass reference to messageCallback
      subscribe(this.channelName, -1, messageCallback.bind(this)).then((response) => {
          // Response contains the subscription information on subscribe call
          console.log(
              'Subscription request sent to: ',
              JSON.stringify(response.channel)
          );
          this.subscription = response;
      });
  }

  // Handles unsubscribe button click
  handleUnsubscribe() {

      // Invoke unsubscribe method of empApi
      unsubscribe(this.subscription, (response) => {
          console.log('unsubscribe() response: ', JSON.stringify(response));
          // Response is true for successful unsubscribe
      });
  }

  registerErrorListener() {
      // Invoke onError empApi method
      onError((error) => {
          console.log('Received error from server: ', JSON.stringify(error));
          // Error contains the server-side error
      });
  }

  beforeUnloadHandler(event) {
    this.handleUnsubscribe();
  }
    // NOT WORKING
    /*
    @api watchedField;
    @api recordId;
    @api objectApiName;
    @track field = this.objectApiName + '.' + this.watchedField
    @track record;
    @track error;

    connectedCallback(){
        this.field = this.objectApiName + '.' + this.watchedField

        window.setTimeout(this.refresh, 1000);
    }


        
    refresh() {
        console.log('bla');
        refreshApex(this.wiredRecord);
        window.setTimeout(this.refresh, 1000);
    }

    


    @wire(getRecord, { recordId: '$recordId', fields: '$field' })
    wiredRecord({ error, data }) {
        console.log('Tentativa de conectar-se ao record')
        //console.log(this.objectApiName)
        //console.log(this.watchedField)
        //console.log(this.field)
        //console.log(data)
        //console.log(error)
        if (data) {
          const oldData = this.record;
          this.record = data;
          console.log('conectado')
          if(getFieldValue(oldData, '$watchedField') !== getFieldValue(data, '$watchedField')) {
            eval("$A.get('e.force:refreshView').fire();")
            console.log('deu refresh!')
          }
        }
        else if (error) {
            this.error = error;
            this.record = undefined;
            console.log('erro ao conectar: ' + error)
        }
      }
      */
      //TODO: https://salesforce.stackexchange.com/questions/306496/does-wire-provide-the-latest-updates-to-a-record-if-changed-on-another-tab-tri
      // https://developer.salesforce.com/docs/component-library/bundle/lightning-emp-api/documentation
      // https://developer.salesforce.com/docs/atlas.en-us.change_data_capture.meta/change_data_capture/cdc_intro.htm
}