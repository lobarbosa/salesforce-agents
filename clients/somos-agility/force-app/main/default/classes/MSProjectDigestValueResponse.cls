public class MSProjectDigestValueResponse {

	public class SupportedSchemaVersions { 
		public String element;
	}

	public String WebFullUrl;
	public SupportedSchemaVersions SupportedSchemaVersions;
	public String SiteFullUrl;
	public String LibraryVersion;
	public String FormDigestValue;
	public List<Integer> FormDigestTimeoutSeconds;

	
	public static MSProjectDigestValueResponse parse(String json) {
		return (MSProjectDigestValueResponse) System.JSON.deserialize(json, MSProjectDigestValueResponse.class);
	}
}