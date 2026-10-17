public without sharing class UtilSchema {

    @AuraEnabled
    public static Map<String,String> getObjectFieldLabels(String objeto){

        Map<String,Schema.SObjectField> mapObjectFields = Schema.getGlobalDescribe().get(objeto).getDescribe().fields.getMap();

        Map<String,String> mapFieldLabels = new Map<String,String>();
        for(String fieldName : mapObjectFields.keySet()) {
            String label = mapObjectFields.get(fieldName).getDescribe().getLabel();
            mapFieldLabels.put(fieldName, label);
        }

        System.debug(mapFieldLabels);
        return mapFieldLabels;
    }

}