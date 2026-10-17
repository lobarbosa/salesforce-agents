public class PPMProjectBO {
	
    public static void calculateDespesasRealizadas(List<PPM_Project__c> listProjects) {
        for(PPM_Project__c p : listProjects) {
            p.Despesas_Realizadas__c = 
                (p.DespesasRealizadasAtividades__c == null ? 00.00 : p.DespesasRealizadasAtividades__c) + 
                (p.DespesasRealizadasCoffeeBreaks__c == null ? 00.00 : p.DespesasRealizadasCoffeeBreaks__c) + 
                (p.DespesasRealizadasPassagens__c == null ? 00.00 : p.DespesasRealizadasPassagens__c);
        }
    }
    
    public static void updateInProject(Map<Id, PPM_Project__c> mapOld, List<PPM_Project__c> listProjects) {
        for(PPM_Project__c p : listProjects) {
            if(!mapOld.containsKey(p.Id))
                continue;
            
            if(p.IdMSProject__c == null)
                continue;
            
            if(mapOld.get(p.Id).Despesas_Realizadas__c != p.Despesas_Realizadas__c || 
               mapOld.get(p.Id).Total_de_creditos_de_despesas__c != p.Total_de_creditos_de_despesas__c || 
               mapOld.get(p.Id).Project_Status__c != p.Project_Status__c) 
            {
                updateProjectInMSProject(p.Id);
            }
        }
    }

    public static void createInProject(List<PPM_Project__c> listProjects) {
        for(PPM_Project__c p : listProjects) {
            createProjectInMSProject(p.Id);
        }
    }

    @future(callout=true)
    public static void updateProjectInMSProject(String id) {
        PPM_Project__c ppmProject = [SELECT Id, Project_Status__c, Despesas_Realizadas__c, Total_de_creditos_de_despesas__c, Nome_do_Projeto__c, IdMSProject__c, Termino_planejado__c, In_cio_Planejado__c FROM PPM_Project__c where id =: id];

        MSProjectIntegrations.updateProject(ppmProject);
    }

    @future(callout=true)
    public static void createProjectInMSProject(String id) {
        PPM_Project__c ppmProject = [SELECT Id, Project_Status__c, Despesas_Realizadas__c, Total_de_creditos_de_despesas__c, Nome_do_Projeto__c, IdMSProject__c, Termino_planejado__c, In_cio_Planejado__c FROM PPM_Project__c where id =: id];
        
        MSProjectIntegrations.insertProject(ppmProject);
    }
}