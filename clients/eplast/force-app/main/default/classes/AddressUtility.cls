public with sharing class AddressUtility {
    // public static String getFormattedAddress(Address address){
    //     return String.format('{0} - {1}/{2}', new String[]{address.street, address.city, address.state});
    // }

    public static String getFormattedPostalCode(String postalCode){
        if(postalCode.length() < 8)
            return null;
        
        String cleanedPostalCode = postalCode.replaceAll('[^\\d]+', '');
        
        return cleanedPostalCode.substring(0, 5) + '-' + cleanedPostalCode.substring(5);
    }
}