public with sharing class BusinessHoursFlowHelper {

    public class Request {
        @InvocableVariable(required=true)
        public Id businessHoursId;

        @InvocableVariable(required=true)
        public Datetime startDate;

        @InvocableVariable(required=true)
        public Datetime endDate;
    }

    public class Response {
        @InvocableVariable
        public Decimal businessHours;

        @InvocableVariable
        public Decimal nonBusinessHours;

        @InvocableVariable
        public Decimal totalHours;
    }

    @InvocableMethod(label='Calculate Business and Non Business Hours')
    public static List<Response> diff(List<Request> requests) {

        List<Response> results = new List<Response>();

        for (Request r : requests) {

            Response res = new Response();

            if (r.startDate == null || r.endDate == null || r.endDate <= r.startDate) {
                res.businessHours = 0;
                res.totalHours = 0;
                res.nonBusinessHours = 0;
                results.add(res);
                continue;
            }

            Long businessMs = BusinessHours.diff(
                r.businessHoursId,
                r.startDate,
                r.endDate
            );

            Long totalMs = r.endDate.getTime() - r.startDate.getTime();

            res.businessHours = businessMs / 3600000.0;
            res.totalHours = totalMs / 3600000.0;
            res.nonBusinessHours = res.totalHours - res.businessHours;

            results.add(res);
        }

        return results;
    }
}