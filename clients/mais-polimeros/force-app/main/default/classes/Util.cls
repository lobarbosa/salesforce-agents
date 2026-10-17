/*
	@author Diego Moreira
	@class Classe de metodos utilitarios
*/
public class Util {
    /*
     * Retorna uma String a partir de um Object. 
     * Se o objeto for igual a NULL, retorna null, caso contrário, faz a conversão e retorna uma String sem os espaços iniciais e finais(trim()). 
     * @param obj Um Object qualquer.
     * @return O objeto convertido em String.
     */
    /*public static String getId( Object obj ) { 
        return ( String.valueOf( obj ).equals( '' ) ? NULL : String.valueOf( obj ) );
    }*/

	/*
     * Retorna uma String a partir de um Object. 
     * Se o objeto for igual a NULL, retorna uma String vazia, caso contrário, faz a conversão e retorna uma String sem os espaços iniciais e finais(trim()). 
     * @param obj Um Object qualquer.
     * @return O objeto convertido em String.
     */
    public static String getString( Object obj ) { 
        return ( obj == null ? '' : String.valueOf( obj ) );
    }


     public static Date getDate( Object obj ) {
        return ( obj == '' ? null : Date.parse( String.valueOf(obj) ) );
    }

    public static Boolean getBoolean( Object obj ) {
        return ( obj == null ? false : Boolean.valueOf( obj ) );
    }

    /**
    *   Retorna o próprio Double recebido se ele for diferente de NULL.
    *   Se for igual a NULL retorna ZERO.
    *   @param valor Um Double qualquer.
    *   @return O próprio Double recebido ou ZERO.
    */
    /*public static Double getDouble( Object valor ) {
        return ( valor == null ? 0 : Double.valueOf( valor ) );
    }*/

    /**
    *   Retorna o próprio Decimal recebido se ele for diferente de NULL.
    *   Se for igual a NULL retorna ZERO.
    *   @param valor Um Decimal qualquer.
    *   @return O próprio Decimal recebido ou ZERO.
    */
    public static Decimal getDecimal( String valor ) {
        return ( valor == null || valor == '' ? 0 : Decimal.valueOf( valor ) );
    }

    /**
    *
    *
    */
    /*public static String replaceCharacters( String valor ) {
        return valor.replace( '.', '' ).replace( '-', '' ).replace( '/', '' );
    }*/
    /**
    *    Retorna modelo dados apos integração
    *    @param status de retorno do serviço
    *    @param mensagem de retorno do serviço
    */
    public static String jsonResponse( String status, String mensagem ) {
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeStringField( 'status', status ); 
        gen.writeStringField( 'mensagem', mensagem ); 
        gen.writeEndObject(); 

        return gen.getAsString();
    }

    /*public static String jsonResponse( String status, String mensagem, String recordId ) {
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeStringField( 'status', status ); 
        gen.writeStringField( 'mensagem', mensagem ); 
        gen.writeStringField( 'recordId', recordId == null ? '' : recordId ); 
        gen.writeEndObject(); 

        return gen.getAsString();
    }*/
}