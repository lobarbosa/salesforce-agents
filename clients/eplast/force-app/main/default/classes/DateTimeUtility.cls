public with sharing class DateTimeUtility {
    public static String formatDate(Date dateToFormat){

        return dateToFormat != null ? dateToFormat.format() : Date.today().format();
    }
}