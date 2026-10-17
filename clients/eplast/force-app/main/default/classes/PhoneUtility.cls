public with sharing class PhoneUtility {
    public static String formatPhone(String phone){
        if(checkPhoneIsInvalid(phone))
            return null;

        String formattedPhone = String.format('({0}){1}', new String[]{phone.substring(0, 2), phone.substring(2)});

        return formattedPhone;
    }

    public static String cleanPhone(String phone){
        if(checkPhoneIsInvalid(phone))
            return null;
            
        return phone.replaceAll('[^\\d-]', '');
    }

    public static Map<String, String> getPhoneInParts(String phone){
        String cleanedPhone = cleanPhone(phone);
        
        if(cleanedPhone == null)
            return null;
        
        Map<String, String> phoneParts = new Map<String, String>();

        phoneParts.put('ddd', cleanedPhone.substring(0, 2));
        phoneParts.put('phone', cleanedPhone.substring(2));

        return phoneParts;
    }

    public static Boolean checkPhoneIsInvalid(String phone){
        return phone == null || phone.length() < 10;
    }
}