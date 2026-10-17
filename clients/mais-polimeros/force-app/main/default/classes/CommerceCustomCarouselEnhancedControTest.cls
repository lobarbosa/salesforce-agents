@IsTest
public class CommerceCustomCarouselEnhancedControTest {

    @IsTest (Seealldata=true)
    public static void mainTest() {

        ManagedContent result = [
            SELECT ContentKey
            FROM ManagedContent
            WHERE AuthoredManagedContentSpace.Name LIKE '%Loja Mais Polímeros%'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        ManagedContentChannel channel = [SELECT Name FROM ManagedContentChannel WHERE Name LIKE '%Loja Mais Polímeros%' LIMIT 1];

        CommerceCustomCarouselEnhancedController.getContentKey(channel.Name, result.ContentKey, 'B2C');
    }
}