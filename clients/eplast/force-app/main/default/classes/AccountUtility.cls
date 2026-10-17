public virtual class AccountUtility {
    private static Integer[] CNPJFirstVerifyingDigitWeights = new Integer[]{ 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 };
    private static Integer[] CNPJSecontVerifyingDigitWeights = new Integer[]{ 6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 };

    public static Boolean validateCNPJ(String cnpj){
        String cleanCNPJ = cleanCNPJ(cnpj);
                                                            // This Regex searches for same-number CNPJ, like 11111111111111, 22222222222222, etc
        if(cleanCNPJ == null || cleanCNPJ.length() != 14 || Pattern.matches('(\\d)\\1{13}', cleanCNPJ))
            return false;

        return validateFirstVerifyingDigit(cleanCNPJ) && validateSecondVerifyingDigit(cleanCNPJ);
    }

    public static String cleanCNPJ(String cnpj){
        if(cnpj == null || cnpj.length() < 14)
            return null;

        return cnpj.replaceAll('[^\\d]', '');
    }

    private static Boolean validateFirstVerifyingDigit(String cnpj){
        String positionsToValidate = cnpj.substring(0, 12);
        String informedFirstVerifyingDigit = cnpj.substring(12, 13);

        return calculateVerifyingDigit(positionsToValidate, informedFirstVerifyingDigit, CNPJFirstVerifyingDigitWeights) == informedFirstVerifyingDigit;
    }

    private static Boolean validateSecondVerifyingDigit(String cnpj){
        String positionsToValidate = cnpj.substring(0, 13);
        String informedSecondVerifyingDigit = cnpj.substring(13, 14);

        return calculateVerifyingDigit(positionsToValidate, informedSecondVerifyingDigit, CNPJSecontVerifyingDigitWeights) == informedSecondVerifyingDigit;
    }

    private static String calculateVerifyingDigit(String verifyingDigitPositions, String informedVerifyingDigit, Integer[] verifyingDigitWeights){
        Integer positionValueResults = 0;
        Integer verifyingDigitResult = 0;

        for(Integer index = 0; index < verifyingDigitPositions.length(); index++)
            positionValueResults += Integer.valueOf(verifyingDigitPositions.substring(index, index + 1)) * verifyingDigitWeights.get(index);

        verifyingDigitResult = Math.mod(positionValueResults, 11);

        return String.valueOf(verifyingDigitResult < 2 ? 0 : 11 - verifyingDigitResult);
    }

    public static String formatCNPJ(String cnpj){
        String cleanCNPJ = cleanCNPJ(cnpj);

        if(cleanCNPJ == null || cleanCNPJ.length() != 14)
            return null;

        // get CNPJ sepparated in groups
        Matcher matcher = Pattern.compile('(\\d{2})(\\d{3})(\\d{3})(\\d{4})(\\d{2})').matcher(cleanCNPJ);

        matcher.matches(); // runs the regex against cnpj string
        
        return String.format('{0}.{1}.{2}/{3}-{4}', new String[]{matcher.group(1), matcher.group(2), matcher.group(3), matcher.group(4), matcher.group(5)});
    }

    public static Account[] getAccountsById(Set<Id> ids){
        Account[] accounts = [
                                SELECT 
                                    Id, 
                                    Store__c,
                                    CompanyName__c, 
                                    BillingPostalCode,
                                    BillingStreet,
                                    BillingCity,
                                    BillingState,
                                    BillingCountry, 
                                    BillingNeighborhood__c,
                                    Phone, 
                                    CompanyDocument__c, 
                                    Owner.ProtheusSellerId__c,
                                    (SELECT User.ProtheusSellerId__c FROM AccountTeamMembers),
                                    Risk__c, 
                                    LimitAmount__c, 
                                    LimitAmountDueDate__c, 
                                    Email__c,
                                    CNAE__c,
                                    Parent.LimitAmount__c,
                                    Parent.LimitAmountDueDate__c
                                FROM Account 
                                WHERE 
                                    Id IN :ids
                            ];

        return (accounts.size() > 0 ? accounts : new Account[]{});
    }

    public static Boolean checkAccountTeamMembers(AccountTeamMember[] teamMembers){
        String teamMemberProtheusSellerId = (teamMembers == null || teamMembers.isEmpty() ? null : teamMembers.get(0).User.ProtheusSellerId__c);
		System.debug('Seller Id ' + teamMemberProtheusSellerId + ' teamMembers ' + teamMembers);
        if(teamMemberProtheusSellerId == null || teamMemberProtheusSellerId.length() == 0)
            return false;

        return true;
    }
}