public with sharing class StringUtility {
    // public static String replaceLowerCaseVowelsAccent(String content){
    //     content = content.replaceAll('[áàâã]', 'a');
    //     content = content.replaceAll('[éê]', 'e');
    //     content = content.replaceAll('[í]', 'i');
    //     content = content.replaceAll('[óôõ]', 'o');
    //     content = content.replaceAll('[ú]', 'u'); 

    //     return content;
    // }

    // public static String replaceUpperCaseVowelsAccent(String content){
    //     content = content.replaceAll('[ÁÀÂÃ]', 'A');
    //     content = content.replaceAll('[ÉÊ]', 'E');
    //     content = content.replaceAll('[Í]', 'I');
    //     content = content.replaceAll('[ÓÔÕ]', 'O');
    //     content = content.replaceAll('[Ú]', 'U'); 

    //     return content;
    // }

    public static String replaceAllCaseVowelsAccent(String content){
        content = content.replaceAll('(?iu)[áàãâ]', 'a');
        content = content.replaceAll('(?iu)[éê]', 'e');
        content = content.replaceAll('(?iu)[í]', 'i');
        content = content.replaceAll('(?iu)[óõô]', 'o');
        content = content.replaceAll('(?iu)[ú]', 'u');

        return content;
    }
}