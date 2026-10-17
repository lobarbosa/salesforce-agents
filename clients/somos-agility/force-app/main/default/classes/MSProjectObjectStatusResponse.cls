public class MSProjectObjectStatusResponse {
    
    public MSProjectObjectStatusResponse(){
        
    }
    
    public d d;
    public Error error;

    public class d {
        public List<response> results;
    }

    public class response {
        public string Value;
        public String FullValue;
        public String InternalName;
        public String SortIndex;
    }

    public class Error {
        public string code;
        public ErrorMessage message;
    }

    public class ErrorMessage {
        public string value;
    }
}