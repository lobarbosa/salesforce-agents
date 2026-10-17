public class MSProjectObjectResponse {
    
    public MSProjectObjectResponse(){
        
    }

    public d d;
    public Error error;

    public class d {
        public String Id;
    }

    public class Error {
        public string code;
        public ErrorMessage message;
    }

    public class ErrorMessage {
        public string value;
    }
}