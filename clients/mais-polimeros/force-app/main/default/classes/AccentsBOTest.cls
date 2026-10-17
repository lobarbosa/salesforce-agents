@isTest public /*with sharing*/ class AccentsBOTest {
    @IsTest
    static void removeDiacriticsTest(){
        
        String text = AccentsBO.removeDiacritics('éíóêôûüïöãñõî');
        
        System.assertEquals('eioeouuioanoi', text);
    }
}