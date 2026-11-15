/**
 * EPLAST-33. Regras puras de classificacao dos sinais comerciais.
 * Sem SOQL e sem DML: recebe fatos agregados e parametros e devolve sinais (nao gravados).
 * Os limites sao estritos onde o criterio de aceite pede "mais de" (CA-01/02, CA-05/06) e
 * inclusivos onde pede "30% ou mais" e "menos de 5" (CA-08, CA-11).
 */
public with sharing class CommercialSignalService {

    public static final String TYPE_RECOVERY = 'Recuperacao';
    public static final String TYPE_NEVER = 'NuncaComprou';
    public static final String TYPE_DROP = 'QuedaVolume';
    public static final String TYPE_RISE = 'AltaVolume';
    public static final String TYPE_CROSS = 'Cruzada';

    /** Parametros do calculo. Valores padrao = registro Default do CMDT (premissas do design). */
    public class Settings {
        public Integer recoveryDays = 60;
        public List<String> purchaseStatuses = new List<String>{ 'Faturamento', 'Concluido' };
        public Integer volumeWindowMonths = 3;
        public Decimal volumeThresholdPercent = 30;
        public Boolean directionDrop = true;
        public Boolean directionRise = true;
        public String crossSellGroupField = 'Industry';
        public Integer crossSellLookbackMonths = 12;
        public Integer crossSellRecentDays = 180;
        public Decimal crossSellMinSharePercent = 30;
        public Integer crossSellMinGroupSize = 5;
        public Integer crossSellMaxPerAccount = 10;
        public Integer batchSize = 100;
        public Boolean includeNeverPurchased = true;
    }

    /** Produto elegivel a cruzada em um grupo, com a participacao do grupo. */
    public class Candidate {
        public Id productId;
        public Decimal sharePercent;
        public Integer buyers;
        public Integer groupSize;
    }

    /** Fatos de uma conta, ja agregados pelo batch. */
    public class AccountFacts {
        public Id accountId;
        public String groupValue;
        public Date lastPurchase;
        public Decimal baseAmount = 0;
        public Decimal currentAmount = 0;
        public Set<Id> recentProducts = new Set<Id>();
    }

    /** Le o registro Default do CMDT; campos vazios ou registro ausente mantem o padrao. */
    public static Settings loadSettings() {
        Settings s = new Settings();
        CommercialSignalSetting__mdt m = CommercialSignalSetting__mdt.getInstance('Default');
        if (m == null) {
            return s;
        }
        if (m.RecoveryDays__c != null) { s.recoveryDays = Integer.valueOf(m.RecoveryDays__c); }
        if (String.isNotBlank(m.PurchaseStatuses__c)) { s.purchaseStatuses = splitList(m.PurchaseStatuses__c); }
        if (m.VolumeWindowMonths__c != null && m.VolumeWindowMonths__c > 0) { s.volumeWindowMonths = Integer.valueOf(m.VolumeWindowMonths__c); }
        if (m.VolumeThresholdPercent__c != null) { s.volumeThresholdPercent = m.VolumeThresholdPercent__c; }
        if (String.isNotBlank(m.VolumeDirections__c)) {
            String d = m.VolumeDirections__c.toLowerCase();
            s.directionDrop = d.contains('queda');
            s.directionRise = d.contains('alta');
        }
        if (String.isNotBlank(m.CrossSellGroupField__c)) { s.crossSellGroupField = m.CrossSellGroupField__c.trim(); }
        if (m.CrossSellLookbackMonths__c != null) { s.crossSellLookbackMonths = Integer.valueOf(m.CrossSellLookbackMonths__c); }
        if (m.CrossSellRecentDays__c != null) { s.crossSellRecentDays = Integer.valueOf(m.CrossSellRecentDays__c); }
        if (m.CrossSellMinSharePercent__c != null) { s.crossSellMinSharePercent = m.CrossSellMinSharePercent__c; }
        if (m.CrossSellMinGroupSize__c != null) { s.crossSellMinGroupSize = Integer.valueOf(m.CrossSellMinGroupSize__c); }
        if (m.CrossSellMaxPerAccount__c != null) { s.crossSellMaxPerAccount = Integer.valueOf(m.CrossSellMaxPerAccount__c); }
        if (m.BatchSize__c != null && m.BatchSize__c > 0) { s.batchSize = Integer.valueOf(m.BatchSize__c); }
        s.includeNeverPurchased = m.IncludeNeverPurchased__c == true;
        return s;
    }

    /** Campo de grupo vindo do CMDT so vale se existir em Account; senao volta para Industry. */
    public static String resolveGroupField(String configured) {
        if (String.isNotBlank(configured)) {
            Schema.SObjectField f = Schema.SObjectType.Account.fields.getMap().get(configured.trim().toLowerCase());
            if (f != null) {
                return f.getDescribe().getName();
            }
        }
        return 'Industry';
    }

    public static List<String> splitList(String raw) {
        List<String> result = new List<String>();
        if (String.isBlank(raw)) {
            return result;
        }
        for (String part : raw.split(';')) {
            if (String.isNotBlank(part)) {
                result.add(part.trim());
            }
        }
        return result;
    }

    /** Conta de grupo vazio fica fora da cruzada (CA-10). */
    public static String groupKey(Object rawValue) {
        if (rawValue == null) {
            return null;
        }
        String v = String.valueOf(rawValue).trim();
        return String.isBlank(v) ? null : v;
    }

    public static String signalKey(Id accountId, String type, Id productId) {
        return accountId + '-' + type + '-' + (productId == null ? '' : String.valueOf(productId));
    }

    /** Recuperacao: mais de N dias desde a ultima compra valida (61 entra, 60 e 59 nao). */
    public static Boolean isRecovery(Date lastPurchase, Date today, Integer thresholdDays) {
        if (lastPurchase == null || today == null || thresholdDays == null) {
            return false;
        }
        return lastPurchase.daysBetween(today) > thresholdDays;
    }

    /**
     * Volume: devolve QuedaVolume, AltaVolume ou null. Base zero ou ausente nunca classifica (CA-07).
     * Comparacao exata, sem arredondar: |atual - base| * 100 > limite * base.
     */
    public static String classifyVolume(Decimal baseAmount, Decimal currentAmount, Settings s) {
        Decimal base = baseAmount == null ? 0 : baseAmount;
        Decimal cur = currentAmount == null ? 0 : currentAmount;
        if (base <= 0) {
            return null;
        }
        Decimal diffScaled = (cur - base) * 100;
        Decimal threshold = s.volumeThresholdPercent * base;
        if (s.directionDrop && -diffScaled > threshold) {
            return TYPE_DROP;
        }
        if (s.directionRise && diffScaled > threshold) {
            return TYPE_RISE;
        }
        return null;
    }

    /** Variacao absoluta em %, uma casa decimal, so para exibicao. */
    public static Decimal variationPercent(Decimal baseAmount, Decimal currentAmount) {
        if (baseAmount == null || baseAmount <= 0) {
            return null;
        }
        Decimal cur = currentAmount == null ? 0 : currentAmount;
        return (Math.abs(cur - baseAmount) * 100 / baseAmount).setScale(1, RoundingMode.HALF_UP);
    }

    /** Produtos do grupo que passam nos limites de tamanho e participacao, do maior % para o menor. */
    public static List<Candidate> qualifyGroup(Integer groupSize, Map<Id, Integer> buyersByProduct, Settings s) {
        List<Candidate> result = new List<Candidate>();
        if (groupSize == null || groupSize < s.crossSellMinGroupSize || groupSize <= 0) {
            return result;
        }
        for (Id productId : buyersByProduct.keySet()) {
            Integer buyers = buyersByProduct.get(productId);
            // buyers/groupSize*100 >= limite, sem divisao: buyers*100 >= limite*groupSize
            if (buyers * 100 >= s.crossSellMinSharePercent * groupSize) {
                Candidate c = new Candidate();
                c.productId = productId;
                c.buyers = buyers;
                c.groupSize = groupSize;
                c.sharePercent = (Decimal.valueOf(buyers) * 100 / groupSize).setScale(1, RoundingMode.HALF_UP);
                result.add(c);
            }
        }
        sortCandidates(result);
        return result;
    }

    /** Ordena por participacao decrescente; empate por Id, para resultado deterministico. */
    public static void sortCandidates(List<Candidate> items) {
        for (Integer i = 1; i < items.size(); i++) {
            Candidate key = items[i];
            Integer j = i - 1;
            while (j >= 0 && isBefore(key, items[j])) {
                items[j + 1] = items[j];
                j--;
            }
            items[j + 1] = key;
        }
    }

    private static Boolean isBefore(Candidate a, Candidate b) {
        if (a.sharePercent != b.sharePercent) {
            return a.sharePercent > b.sharePercent;
        }
        return String.valueOf(a.productId) < String.valueOf(b.productId);
    }

    /** Todos os sinais de uma conta na data de calculo. Nao grava. */
    public static List<CommercialSignal__c> buildSignals(
        AccountFacts f, Date today, Settings s, Map<String, List<Candidate>> qualifiedByGroup
    ) {
        List<CommercialSignal__c> out = new List<CommercialSignal__c>();
        if (f.lastPurchase == null) {
            if (s.includeNeverPurchased) {
                out.add(base(f, TYPE_NEVER, today, null,
                    'Nenhum pedido com status de compra (' + String.join(s.purchaseStatuses, ', ') + ').'));
            }
        } else if (isRecovery(f.lastPurchase, today, s.recoveryDays)) {
            CommercialSignal__c r = base(f, TYPE_RECOVERY, today, null,
                'Ultima compra em ' + f.lastPurchase.format() + ', ha ' + f.lastPurchase.daysBetween(today)
                + ' dias; limite de ' + s.recoveryDays + ' dias.');
            r.LastPurchaseDate__c = f.lastPurchase;
            r.DaysWithoutPurchase__c = f.lastPurchase.daysBetween(today);
            out.add(r);
        }
        String volumeType = classifyVolume(f.baseAmount, f.currentAmount, s);
        if (volumeType != null) {
            Integer n = s.volumeWindowMonths;
            CommercialSignal__c v = base(f, volumeType, today, null,
                'Ultimos ' + n + ' meses: ' + f.currentAmount.setScale(2) + '; ' + n + ' meses anteriores: '
                + f.baseAmount.setScale(2) + '; limite de ' + s.volumeThresholdPercent + '%.');
            v.BasePeriodAmount__c = f.baseAmount;
            v.CurrentPeriodAmount__c = f.currentAmount;
            v.VariationPercent__c = variationPercent(f.baseAmount, f.currentAmount);
            v.LastPurchaseDate__c = f.lastPurchase;
            out.add(v);
        }
        if (f.groupValue != null && qualifiedByGroup != null && qualifiedByGroup.containsKey(f.groupValue)) {
            Integer count = 0;
            for (Candidate c : qualifiedByGroup.get(f.groupValue)) {
                if (count >= s.crossSellMaxPerAccount) {
                    break;
                }
                if (f.recentProducts.contains(c.productId)) {
                    continue;
                }
                CommercialSignal__c x = base(f, TYPE_CROSS, today, c.productId,
                    c.sharePercent + '% das ' + c.groupSize + ' contas do grupo "' + f.groupValue
                    + '" compraram o produto em ' + s.crossSellLookbackMonths + ' meses; esta conta nao comprou em '
                    + s.crossSellRecentDays + ' dias.');
                x.Product__c = c.productId;
                x.VariationPercent__c = c.sharePercent;
                x.LastPurchaseDate__c = f.lastPurchase;
                out.add(x);
                count++;
            }
        }
        return out;
    }

    private static CommercialSignal__c base(AccountFacts f, String type, Date today, Id productId, String reason) {
        CommercialSignal__c sig = new CommercialSignal__c();
        sig.Account__c = f.accountId;
        sig.Type__c = type;
        sig.CalculationDate__c = today;
        sig.SignalKey__c = signalKey(f.accountId, type, productId);
        sig.Reason__c = reason.length() > 255 ? reason.substring(0, 255) : reason;
        return sig;
    }
}
