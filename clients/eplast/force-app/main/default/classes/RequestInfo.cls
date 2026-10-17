public with sharing class RequestInfo {
    public HttpRequest request;
    public HttpResponse response;

    public RequestInfo(HttpRequest request, HttpResponse response){
        this.request = request;
        this.response = response;
    }
}