/* 
 * The purpose of this class is to test the quoteExt class.  The @IsTest annotation
 * excludes this class from the system cache and as such it is not counted against the
 * org code size limit. NOTE: this test and the sample ASSUMES the organization has 
 * opportunity products enabled and does NOT have multi-currency enabled.
 */
@IsTest private class quoteExtTests {
    
    /* This is a basic test which simulates the primary positive case for the 
       save method in the quoteExt class. */
    public static testmethod void basicSaveTest() {
    
        Opportunity o = quoteExtTests.setupTestOpportunity();
        
        /* Construct the standard controller for quote. */
        ApexPages.StandardController con = new ApexPages.StandardController(new Quote__c());
        
        /* Switch to runtime context */
        Test.startTest();
        
        /* Construct the quoteExt class */
        QuoteExt ext = new QuoteExt(con);
        
        /* Call save on the ext */
        PageReference result = ext.save();
        
        /* Switch back to test context */
        Test.stopTest();
        
        /* Verify the navigation outcome is as expected */
        System.assertEquals(result.getUrl(), con.view().getUrl());
        
        /* Verify the oppty amount is equivalent to the quote amount */
        Decimal opportunityAmount = [select amount from opportunity where id = :o.id].amount;
        Decimal quoteAmount       = [select total_price__c from quote__c where id = :con.getId()].total_price__c;        
        System.assertEquals(opportunityAmount, quoteAmount);
        
    }
    
    /* This is a basic test which simulates the primary positive case for the 
       attachQuote method in the quoteExt class. */
    public static testmethod void basicAttachTest() {
        Opportunity o = quoteExtTests.setupTestOpportunity();
        
        /* Construct the standard controller for quote. */
        ApexPages.StandardController con = new ApexPages.StandardController(new Quote__c());
        
        /* Construct the quoteExt class */
        QuoteExt ext = new QuoteExt(con);
        
        /* Call save on the ext */
        ext.save();       
        
        /* Set the extension quote object using the id on the controller. */
        ext.q = new quote__c(id = con.getId());  
        /* UNCOMMENT THIS AND RE-RUN THE TEST TO REPRO THE GACK
        */con.getRecord(); 
        
        /* Switch to runtime context */
        Test.startTest();
        
        /* Simulate the button invocation of the attachQuote action method 
           on the extension. */
        PageReference result = ext.attachQuote();
        
         /* Switch back to test context */
        Test.stopTest();
        
        /* Verify the navigation outcome is as expected */
        System.assertEquals(result.getUrl(), con.view().getUrl());
        
        /* Verify the attachment was created. */
       System.assert([select name from attachment where parentid = :con.getId()].name != null);
        
        
      
    }
    
    /* This setup method will create an opporutnity with line items and a primary
       contact role for use in various tests. */
    private static Opportunity setupTestOpportunity() {
        
        /* Create an account */
        Account a = new Account();
        a.name    = 'TEST';
        Database.insert(a);
        
        /* Get the standard pricebook. There must be a standard pricebook already 
           in the target org.  */
        Pricebook2 pb = [select name, isactive from Pricebook2 where IsStandard = true limit 1];
        
        if(!pb.isactive) {
            pb.isactive = true;
            Database.update(pb);
        }
        
        /* Get a valid stage name */
        OpportunityStage stage = [select MasterLabel from OpportunityStage limit 1];
        
        /* Setup a basic opportunity */
        Opportunity o  = new Opportunity();
        o.Name         = 'TEST';
        o.AccountId    = a.id;
        o.CloseDate    = Date.today();
        o.StageName    = stage.masterlabel;
        o.Pricebook2Id = pb.id;
        
        /* Create the opportunity */
        Database.insert(o);
        
        /* Create a contact */
        Contact c = new Contact();
        c.lastname = 'LASTNAME';
        c.firstname = 'FIRSTNAME';
        
        Database.insert(c);
        
        /* Create the opportunity contact role */
        OpportunityContactRole r = new OpportunityContactRole();
        r.ContactId     = c.id;
        r.OpportunityId = o.id;
        r.IsPrimary     = true;
        r.role          = 'ROLE';
        
        Database.insert(r);
        
        /* Create a product2 */
        Product2 p = new Product2();
        p.Name = 'TEST';
        
        Database.insert(p);
        
        /* Create a pricebook entry. */
        PricebookEntry pbe = new PricebookEntry();
        pbe.Pricebook2Id = pb.id;
        pbe.Product2Id   = p.id;
        pbe.IsActive     = true;
        pbe.UnitPrice    = 1;
        
        Database.insert(pbe);
        
        /* Create a line item */
        OpportunityLineItem i = new OpportunityLineItem();
        i.opportunityId = o.id;
        i.pricebookentryid = pbe.id;
        i.quantity = 1;
        i.unitprice = 1;
        
        Database.insert(i);
        
        /* Set up the opportunity with the related records */
        r.Contact                 = c;
        r.Opportunity             = o;
        o.Account                 = a;
        i.Opportunity             = o;
        pbe.Product2              = p;
        pbe.Pricebook2            = pb;
        i.PricebookEntry          = pbe;
        
        /* Set the request parameter that the constructor for quoteExt is expecting */
        PageReference pref = Page.quoteNew;
        pref.getParameters().put('oppid',o.id);
        Test.setCurrentPage(pref);
        
        return o;
        
    }
    
}