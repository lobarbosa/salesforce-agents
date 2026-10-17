@isTest
private class BusinessHoursFlowHelperTest {

    @isTest
    static void testDiff_ValidRange() {

        // Pega um Business Hours padrão do org
        BusinessHours bh = [SELECT Id FROM BusinessHours LIMIT 1];

        Datetime startDt = Datetime.newInstance(2024, 1, 1, 9, 0, 0);
        Datetime endDt   = Datetime.newInstance(2024, 1, 1, 17, 0, 0);

        BusinessHoursFlowHelper.Request req = new BusinessHoursFlowHelper.Request();
        req.businessHoursId = bh.Id;
        req.startDate = startDt;
        req.endDate = endDt;

        Test.startTest();
        List<BusinessHoursFlowHelper.Response> resList =
            BusinessHoursFlowHelper.diff(new List<BusinessHoursFlowHelper.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, resList.size());

        BusinessHoursFlowHelper.Response res = resList[0];

        System.assert(res.totalHours > 0);
        System.assert(res.businessHours >= 0);
        System.assertEquals(res.totalHours - res.businessHours, res.nonBusinessHours);
    }

    @isTest
    static void testDiff_InvalidRange() {

        BusinessHours bh = [SELECT Id FROM BusinessHours LIMIT 1];

        Datetime dt = Datetime.now();

        BusinessHoursFlowHelper.Request req = new BusinessHoursFlowHelper.Request();
        req.businessHoursId = bh.Id;
        req.startDate = dt;
        req.endDate = dt; // inválido (igual)

        List<BusinessHoursFlowHelper.Response> resList =
            BusinessHoursFlowHelper.diff(new List<BusinessHoursFlowHelper.Request>{ req });

        BusinessHoursFlowHelper.Response res = resList[0];

        System.assertEquals(0, res.businessHours);
        System.assertEquals(0, res.totalHours);
        System.assertEquals(0, res.nonBusinessHours);
    }

    @isTest
    static void testDiff_NullDates() {

        BusinessHours bh = [SELECT Id FROM BusinessHours LIMIT 1];

        BusinessHoursFlowHelper.Request req = new BusinessHoursFlowHelper.Request();
        req.businessHoursId = bh.Id;
        req.startDate = null;
        req.endDate = null;

        List<BusinessHoursFlowHelper.Response> resList =
            BusinessHoursFlowHelper.diff(new List<BusinessHoursFlowHelper.Request>{ req });

        BusinessHoursFlowHelper.Response res = resList[0];

        System.assertEquals(0, res.businessHours);
        System.assertEquals(0, res.totalHours);
        System.assertEquals(0, res.nonBusinessHours);
    }

    @isTest
    static void testDiff_MultipleRequests() {

        BusinessHours bh = [SELECT Id FROM BusinessHours LIMIT 1];

        Datetime start1 = Datetime.now();
        Datetime end1 = start1.addHours(4);

        Datetime start2 = Datetime.now();
        Datetime end2 = start2.addHours(8);

        BusinessHoursFlowHelper.Request req1 = new BusinessHoursFlowHelper.Request();
        req1.businessHoursId = bh.Id;
        req1.startDate = start1;
        req1.endDate = end1;

        BusinessHoursFlowHelper.Request req2 = new BusinessHoursFlowHelper.Request();
        req2.businessHoursId = bh.Id;
        req2.startDate = start2;
        req2.endDate = end2;

        List<BusinessHoursFlowHelper.Response> resList =
            BusinessHoursFlowHelper.diff(new List<BusinessHoursFlowHelper.Request>{ req1, req2 });

        System.assertEquals(2, resList.size());
    }
}