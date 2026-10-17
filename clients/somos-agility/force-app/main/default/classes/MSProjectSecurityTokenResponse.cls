public class MSProjectSecurityTokenResponse {

	public MSProjectSecurityTokenResponse() {

	}
	
	public class Lifetime {
		public List<String> Expires;
		public String Created;
	}

	public Body Body;
	public Header Header;

	public class RequestedSecurityToken {
		public String BinarySecurityToken;
	}

	public class Header {
		public Security Security;
		public String To;
		public String Action;
	}

	public class AppliesTo {
		public EndpointReference EndpointReference;
	}

	public class RequestSecurityTokenResponse {
		public RequestedSecurityToken RequestedSecurityToken;
		public Lifetime Lifetime;
		public AppliesTo AppliesTo;
		public String TokenType;
	}

	public class Security {
		public Lifetime Timestamp;
	}

	public class Body {
		public RequestSecurityTokenResponse RequestSecurityTokenResponse;
	}

	public class EndpointReference {
		public List<String> Address;
	}
}