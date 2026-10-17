/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Item_do_PCATest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Item_do_PCATrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Item_do_PCA__c());
    }
}