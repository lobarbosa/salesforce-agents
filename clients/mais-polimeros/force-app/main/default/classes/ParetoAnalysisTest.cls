@isTest
public class ParetoAnalysisTest {

    @isTest
    public static void test(){
        ParetoAnalysis.ParetoResult pr = new ParetoAnalysis.ParetoResult('A',1,2,'A');
        ParetoAnalysis.calculatePareto(new List<Decimal>{2},new List<String>{'A'});
    }
}