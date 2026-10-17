public class MSProjectIntegrationsMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');

        MSProjectObjectResponse responseMock = new MSProjectObjectResponse();
        responseMock.d = new MSProjectObjectResponse.d();
        responseMock.d.Id = '123';

        MSProjectObjectStatusResponse responseMockStatus = new MSProjectObjectStatusResponse();
        responseMockStatus.d = new MSProjectObjectStatusResponse.d();
        responseMockStatus.d.results = new List<MSProjectObjectStatusResponse.response>();
        
        MSProjectObjectStatusResponse.response statusResponse = new MSProjectObjectStatusResponse.response();
        statusResponse.FullValue = 'DSA em Análise'; statusResponse.Value = 'DSA em Análise'; statusResponse.InternalName = 'DSA em Análise'; statusResponse.SortIndex = '0';
        
        MSProjectObjectStatusResponse.response statusResponse2 = new MSProjectObjectStatusResponse.response();
        statusResponse2.FullValue = 'Em Planejamento'; statusResponse2.Value = 'Em Planejamento'; statusResponse2.InternalName = 'Em Planejamento'; statusResponse2.SortIndex = '1';
        responseMockStatus.d.results.add(statusResponse2);
        
        MSProjectDigestValueResponse digest = new MSProjectDigestValueResponse();
        digest.FormDigestValue = '0xDB9098012AEF0AF44AA5FB247A4661CB2930E9DAB6F010F4C63FA82878A52E1DCB27442AFE6075988ACBCC5D03C55057687F9F7D76F8A3AE2CEA50861D6DF99B,24 Apr 2020 20:17:43 -0000';

        if(request.getEndpoint().contains('/sites/ppm/_api/ProjectServer/Projects'))
            response.setBody(JSON.serialize(responseMock));
        else if(request.getEndpoint().contains('/sites/ppm/_api/ProjectServer/CustomFields(\'985e566c-984b-ea11-bf82-00155db0b607\')/LookupEntries'))
            response.setBody(JSON.serialize(responseMockStatus));
        else if(request.getEndpoint().contains('/extSTS.srf')) 
            response.setBody('<?xml version="1.0" encoding="utf-8"?><S:Envelope xmlns:wsa="http://www.w3.org/2005/08/addressing" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" xmlns:wsp="http://schemas.xmlsoap.org/ws/2004/09/policy" xmlns:wst="http://schemas.xmlsoap.org/ws/2005/02/trust" xmlns:S="http://www.w3.org/2003/05/soap-envelope"><S:Header><wsa:Action S:mustUnderstand="1" wsu:Id="Action">http://schemas.xmlsoap.org/ws/2005/02/trust/RSTR/Issue</wsa:Action><wsa:To S:mustUnderstand="1" wsu:Id="To">http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:To><wsse:Security S:mustUnderstand="1"><wsu:Timestamp wsu:Id="TS" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"><wsu:Created>2020-04-29T01:33:05.7895559Z</wsu:Created><wsu:Expires>2020-04-29T01:38:05.7895559Z</wsu:Expires></wsu:Timestamp></wsse:Security></S:Header><S:Body xmlns:S="http://www.w3.org/2003/05/soap-envelope"><wst:RequestSecurityTokenResponse xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" xmlns:wsp="http://schemas.xmlsoap.org/ws/2004/09/policy" xmlns:wst="http://schemas.xmlsoap.org/ws/2005/02/trust"><wst:TokenType>urn:passport:compact</wst:TokenType><wsp:AppliesTo><wsa:EndpointReference xmlns:wsa="http://www.w3.org/2005/08/addressing"><wsa:Address>agilitynetworksbrazil.sharepoint.com</wsa:Address></wsa:EndpointReference></wsp:AppliesTo><wst:Lifetime><wsu:Created>2020-04-29T01:33:05Z</wsu:Created><wsu:Expires>2020-04-30T01:33:05Z</wsu:Expires></wst:Lifetime><wst:RequestedSecurityToken><wsse:BinarySecurityToken Id="Compact0" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">t=EwD4Ak6hBwAUoI9qUOm+nWxx1GEBzUSgrucLnssAAfxe/ZzJ/E4krKAmkEW2baPubNOPlAbzE8Vy9KJseb6I/aorpAUEMSGjzpGEcRVqOWfNrm1TeiHeFTzyV2xHV9ynPIDh2DeACvWLn+lWKpMFQ4df0gdHH0fLXYpMueiEgjPaNkXfWJlx8o4v+hIDm1U5z8TBv3CChZQz81gTiwjpXnXAtgr0yIcl4Z8S3KQBf4l+tXM4JnRAgwf8VQ9u45ePpUb/cJ9dpT1esOxxC6pR6AUHE6gqbOJ9+y364M6FVJ+BGBRGgRGMnaBuK5KcPhYUNu+bt/t9qZicgw6J6DxlBAos55Wb3J9ESQ2pZvWyUviBHu6CfAB8brwrMyiHwhoDZgAACDBPHy70RsDWyAFZqqrswdqtcAAPsSd7qpCTq+4d0GBTH8e8xBHKO/dIADmYyoLNGNidByfNcVZmvMYuqHgZzqw6MgPz3HbRKzbOWb1GsEQjriXLMG6SQOqfQfRgEQeCCyILuXeKmfn2t/3V4d5VC6AKuUVqtMCWguswXcNflmXd+M2LuoSKCWH7Wnbymvw5vlyYzNzjaSc/yo83JCB2XnM5ivLg/zTpKwYU03KBb3AcbYjuF+ulK38XpriF55v1SYWGzA7HSxYqQLiYEH/xAjaOf2Ra5yL+EeYjl4lSb3CHr9ix7jqB/n6VwyAzS4dr5UxlhK3Ib9KxE/N2Rmiv3JVsYMPkeSv4nS9OGqIFX1mVIvYi2fBl9YI0py3zbuaVgROxLvHo7Xrv2+HcP7KTsfiSW2Bp70dkQgLrriSgxKBQeTywhhhpRqxuCc7k8d0PEZO3KNtox5zySJidtuC7DLBkg3kESI8mu8lK/PBeWBI1xZVFBuhw2FJa1L7AYs45VXopkvF3Q8cCEkV4cjeQ1MEOBZVN8T+aBwj6WFBR+274vSYnnr7J/fr/3+eJVxJm95eQlNTNocHoDfe/KrfVfuNyoT5P6dvM7xswpqi1AnL8bOkrAg==&amp;p=</wsse:BinarySecurityToken></wst:RequestedSecurityToken><wst:RequestedAttachedReference><wsse:SecurityTokenReference xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"><wsse:Reference URI="J/Utz5VM/rLWQtBSnyiwhnmEHzA="></wsse:Reference></wsse:SecurityTokenReference></wst:RequestedAttachedReference><wst:RequestedUnattachedReference><wsse:SecurityTokenReference xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"><wsse:Reference URI="J/Utz5VM/rLWQtBSnyiwhnmEHzA="></wsse:Reference></wsse:SecurityTokenReference></wst:RequestedUnattachedReference></wst:RequestSecurityTokenResponse></S:Body></S:Envelope>');
        else if(request.getEndpoint().contains('/_forms/default.aspx?wa=wsignin1.0'))
            response.setHeader('Set-Cookie', 'FedAuth=77u/PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiPz48U1A+VjcsMGguZnxtZW1iZXJzaGlwfDEwMDMyMDAwOWNjY2Q5YmVAbGl2ZS5jb20sMCMuZnxtZW1iZXJzaGlwfjdGFbS5iciAc29tb3NGtvwMDAwMDAsMTMyMjY3Nzk1bmVhZ2lsaXR5LmNvwxMzIzMjIzMzA2MzANTgwMDAwMDAwLDEzMjMyMzE5NDYzNjk5NjYyOSwwLjAuMC4wMDE4ZS00YjA3LWIxNjYtODVjNmI1YWFkYzE2LCwsZThiNTk0YLDIsNGU1MWE2YTctTMtOGFlNS00ZmU5LDM3LGU4YjU5NGEzLThhZTUtNGZlOLDAsLCwsMjY1MN3VWZHS05YWY2LTcDQ2Nzc0Mzk5OTk5OTk5OTlhZjYtNzAyMTY0NThiMSxQZFVDbjBawMjE2NDU4YjAzNywsMCwwptcjVUTHNSZFBwQ1hCQzZYSDVPZn3JJZU5pcy94TTFjY29QRVUydUJkby9kVkswMHM5UnplekhBbW8xdWxaYXVlbENPOWNwNWgzR1JlUW1CMkhWdjhFTi9lcE1POHZzeWxzUVk4Ukk0MFVOWlN0Y2kzdHVRWkxrYdFMxYXlJK2dYdnMrUWI4ZUpPNXSNms5V2tlWjlHVjcwcUJYRkllZOVUlaMXBhdBEYXFWZGFBYmM1bmVpTlZ5Y1BkbU9FK2VQTm15VlIvlloa3RGYVlqWDJrKyszOFBhVkFxT1BsGS1M5R0E5NU4xQ09QcmhDajZd0hKcWFFV1FvUHNtQ1VNWStOVWVjbDlGTUcxQ3FIcWo2WjJIOHpSMkxNdWtJa0kyRU5hMlpVKanErbzZ2Yk04ckNqZVh5OUlvZDlsU2ZDdnZhbzlIdHBGVE2S2c9PTwvU1A+; path=/; SameSite=None; secure; HttpOnly; rtFa=f4TAcOS0pB76eWsaKxfFocKGTLohXC12456z4epoDjgmNEU1MUE2QTctMDE4RS00QjA3LUIxNjYtODVDNkI1QUFEQzE2u2O+QpJulVByqX+AZ8d0VSUIDChz+o8tjHdhEGJW+bBUjNA3LW+2O8tp12341HesqY2VG/JlXG4x0lZN7UGoD1QU1pKlfa5zB123456BUN9KjakYvZJnbdwzZrXzazFPnsVJurwE+d4bF45H+efU73dgjM06QIyYibjBSCX7rlnuTMf5xxBG4Hf5JJTp8FdNo4bLsGFsOp6zG/Mj+zC7j6aCXEh5BuQ44tJcefDVXgyNeStoDIOaiNVhmektr+bvCx+11LvTIttuzinEmCLPPmOKuqbWE/4rnqG+0HGtFjR1iyRbVmQ6ac6mXx375vsrljw2GXYqbRshX7K2BpHu+0UAAAA=; domain=sharepoint.com; path=/; SameSite=None; secure; HttpOnly;');
        else if(request.getEndpoint().contains('/_api/contextinfo'))
        response.setBody(JSON.serialize(digest));
        
        response.setStatusCode(200);
        response.setStatus('OK');
        
        return response;
    }
 }