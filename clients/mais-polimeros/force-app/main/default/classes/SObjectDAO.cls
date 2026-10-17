/**
 * Classe que define métodos de operações DML comuns a todos objetos SalesForce.
 * Essa classe não pode ser utilizada diretamente, apenas determina o comportamento de suas descendentes.
 * @author Diego Moreira
 */
public abstract class SObjectDAO {
    /**
    * Insere um objeto na base de dados.
    * @param sObj Objeto a ser inserido. Este objeto é qualquer descendente de SObject, sendo possível passar um objeto padrão ou customizado.
    * @return Um objeto SaveResult indicando o resultado da inserção.
    */

    // public Database.SaveResult insertData( SObject sObj ) {
    //     Database.SaveResult sr = null;
        
    //     try {
    //         sr = Database.insert( sObj );
    //     } catch( DMLException ex ) {
    //     	System.debug( '>> EX INSERT: ' + ex.getMessage() );
    //         throw ex;
    //     }         
    //     return sr;
    // }
  
    /**
     * Insere uma lista de objetos na base de dados.
     * @param sObjList A lista de objetos a ser inserida. Esta lista pode ser composta por qualquer
     * descendente de SObject, sendo possível passar uma lista de objetos padrão ou customizados.
     * @return Uma lista de objetos SaveResult indicando o resultado da inserção.
     */
    // public List<Database.SaveResult> insertData( List<SObject> sObjList ) {
    //     List<Database.SaveResult> srList = null;
        
    //     try {
    //         srList = Database.insert( sObjList );
    //     } catch( DMLException ex ) {
    //          throw ex;
    //     }        
    //     return srList;
    // }
    
    /**
    * Atualiza um objeto na base de dados.
    * @param sObj Objeto a ser atualizado. Este objeto é qualquer descendente de SObject, sendo possível passar um objeto padrão ou customizado.
    * @return Um objeto SaveResult indicando o resultado da atualização.
    */
    public Database.SaveResult updateData( SObject sObj ) {
        Database.SaveResult sr = null;
        
        try {
            sr = Database.update( sObj );
        } catch( DMLException ex ) {throw ex;}

        return sr;
    }
    
    /**
    * Atualiza uma lista de objetos na base de dados.
    * @param sObjList A lista de objetos a ser atualizada. Esta lista pode ser composta por qualquer descendente de SObject, 
    * sendo possível passar uma lista de objetos padrão ou customizados.
    * @return Uma lista de objetos SaveResult indicando o resultado da atualização.
    */
    // public List<Database.SaveResult> updateData( List<SObject> sObjList ) {
    //     List<Database.SaveResult> srList = null;
        
    //     try {
    //         srList = Database.update( sObjList );
    //     } catch( DMLException ex ) {
    //         throw ex;
    //     }        
    //     return srList;
    // }
    
    
    // public List<Database.Upsertresult> upsertData( List<SObject> sObjList, Schema.Sobjectfield fieldExtenalId ) {
    //     List<Database.Upsertresult> srList = null;        
    //     try {
    //         srList = Database.upsert( sObjList, fieldExtenalId );
    //     }
    //     catch(DMLException ex) {
    //         throw ex;
    //     }        
    //     return srList;
    // }
    
    /**
    * Deleta um objeto da base de dados.
    * @param id Id do objeto a ser deletado. 
    * @return Um objeto DeleteResult indicando o resultado da deleção.
    */
    // public Database.DeleteResult deleteData( String id ) {
    //     Database.DeleteResult dr = null;
        
    //     try {   
    //         dr = Database.delete( id );
    //     } catch( DMLException ex ) {
    //         throw ex;
    //     }        
    //     return dr;
    // }
    
    /**
    * Deleta uma lista de objetos da base de dados.
    * @param sObjList A lista de Ids a ser deletada. 
    * @return Uma lista de objetos DeleteResult indicando o resultado da deleção.
    */
    // public List<Database.DeleteResult> deleteData( List<String> idList ) {
    //     List<Database.DeleteResult> drList = null;
        
    //     try {
    //         drList = Database.delete( idList );
    //     } catch( DMLException ex ) {
    //         throw ex;
    //     }        
    //     return drList;
    // }
    
    /**
    * Deleta uma lista de objetos da base de dados.
    * @sObjList A lista de objetos a ser deletada. Esta lista pode ser composta por qualquer descendente de SObject
    * @return Uma lista de objetos DeleteResult indicando o resultado da deleção.
    */
    // public List<Database.DeleteResult> deleteData( List<SObject> sObjList ) {
    //     List<Database.DeleteResult> drList = null;
        
    //     try {
    //         drList = Database.delete( sObjList );
    //     } catch( DMLException ex ) {
    //         throw ex;
    //     }        
    //     return drList;
    // }
}