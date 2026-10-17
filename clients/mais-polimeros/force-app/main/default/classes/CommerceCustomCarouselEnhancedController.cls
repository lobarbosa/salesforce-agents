public without sharing class CommerceCustomCarouselEnhancedController {
    
    @AuraEnabled (cacheable=true)
    public static String getContentKey(String channelName, String keys, String storeName){
        try {
            // Dinamic Values
            String channelId = [SELECT Id FROM ManagedContentChannel WHERE Name = :channelName LIMIT 1].id;
            List<String> contentKeys = keys.split(',', 59);

            // Default Values
            String baseUrl = String.isNotBlank(storeName) ? '/'+storeName+'/sfsites/c/cms/delivery/media/' : '/sfsites/c/cms/delivery/media/';

            List<String> managedContentIds = new List<String>();
            String contentTypeFQN;
            String language = 'pt_BR';
            Boolean includeContentBody = false;
            Integer referenceDepth = 3;
            Boolean expandReferences = false;
            Boolean referencesAsList = false;
            Integer pageParam = 0;
            Integer pageSize = 25;
            Boolean showAbsoluteUrl = true;
            
            // Dates
            DateTime dateNow = DateTime.now();
            String publishStartDate = '2000-01-01T00:00:00.000Z';
            String publishEndDate = dateNow.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');

            ConnectApi.ManagedContentDeliveryDocumentCollection obj;
            obj = ConnectApi.ManagedContentDelivery.getManagedContentsForChannel(   channelId,
                                                                                    managedContentIds,
                                                                                    contentKeys,
                                                                                    contentTypeFQN,
                                                                                    language,
                                                                                    publishStartDate,
                                                                                    publishEndDate,
                                                                                    includeContentBody,
                                                                                    referenceDepth,
                                                                                    expandReferences,
                                                                                    referencesAsList,
                                                                                    pageParam,
                                                                                    pageSize,
                                                                                    showAbsoluteUrl);
            
            List<ReturnWrapper> lstlstWrapper = new List<ReturnWrapper>();
            List<ConnectApi.AbstractManagedContentDeliveryDocument> lstContent = obj.contents;
            if(!lstContent.isEmpty()) {
                for(ConnectApi.AbstractManagedContentDeliveryDocument content : lstContent) {
                    ReturnWrapper wrapper = new ReturnWrapper();
                    wrapper.title = content.urlName;
                    wrapper.url = baseUrl + content.contentKey;
                    lstlstWrapper.add(wrapper);
                }
            } else {
                return 'Não foram encontrados itens!';
            }

            return System.JSON.serialize(lstlstWrapper);
        } catch(Exception ex) {
            String error = 'Causa ==> ' + ex.getCause() + '\nLinha ==> ' + ex.getLineNumber() + '\n Mensagem ==>' + ex.getMessage();
            System.debug(error);
            return error;
        }
    }

    public class ReturnWrapper{
        String title {get;set;}
        String url {get;set;}
    }
}