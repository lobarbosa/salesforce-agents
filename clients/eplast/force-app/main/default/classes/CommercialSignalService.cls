/**
 * EPLAST-33. Regras puras de classificacao dos sinais comerciais.
 * Sem SOQL de dados e sem DML: recebe fatos agregados e parametros e devolve sinais (nao gravados).
 *
 * Rodada 17/11: recuperacao a partir de 91 dias (estrito); volume por familia comparando o ultimo
 * mes fechado com a media mensal dos N meses completos anteriores, queda de 20% ou mais (inclusivo);
 * historico insuficiente quando a conta comprou a familia em poucos meses da base; cruzada por
 * segmento (Sector__c), sugerindo familia (ou produto, por parametro).
 */
public with sharing class CommercialSignalService {

    public static final String TYPE_RECOVERY = 'Recuperacao';
    public static final String TYPE_NEVER = 'NuncaComprou';
    public static final String TYPE_DROP = 'QuedaVolume';
    public static final String TYPE_RISE = 'AltaVolume';
    public static final String TYPE_INSUFFICIENT = 'HistoricoInsuficiente';
    public static final String TYPE_CROSS = 'Cruzada';

    /** Rotulo da familia para produto sem grupo (PA-26). Nunca e sugerido na cruzada. */
    public static final String NO_FAMILY = 'Sem familia';
    public static final String UNIT_MIXED = 'MISTA';
    public static final String UNIT_NONE = 'SEM UNIDADE';

    public static final String METRIC_VALUE = 'Valor';
    public static final String METRIC_QUANTITY = 'Quantidade';
    public static final String METRIC_BOTH = 'ValorOuQuantidade';
    public static final String LEVEL_FAMILY = 'Familia';
    public static final String LEVEL_PRODUCT = 'Produto';

    /** Listas permitidas para os campos dinamicos vindos do CMDT (sem texto livre em SOQL). */
    public static final List<String> ALLOWED_DATE_FIELDS = new List<String>{ 'EffectiveDate', 'IssuanceDate__c', 'ActivatedDate' };
    public static final List<String> ALLOWED_FAMILY_FIELDS = new List<String>{ 'Group__c', 'Family' };

    /** Parametros do calculo. Valores padrao = registro Default do CMDT (premissas do design). */
    public class Settings {
        public Integer recoveryDays = 90;
        public List<String> purchaseStatuses = new List<String>{ 'Faturamento', 'Concluido' };
        public Integer volumeWindowMonths = 3;
        public Integer volumeMinBaseMonths = 2;
        public Decimal volumeThresholdPercent = 20;
        public Boolean directionDrop = true;
        public Boolean directionRise = false;
        public String volumeMetric = METRIC_VALUE;
        public String purchaseDateField = 'EffectiveDate';
        public String familyField = 'Group__c';
        public String crossSellGroupField = 'Sector__c';
        public String crossSellLevel = LEVEL_FAMILY;
        public Set<String> crossSellExcludedFamilies = new Set<String>();
        public Integer crossSellLookbackMonths = 12;
        public Integer crossSellRecentDays = 180;
        public Decimal crossSellMinSharePercent = 30;
        public Integer crossSellMinGroupSize = 5;
        public Integer crossSellMaxPerAccount = 10;
        public Integer batchSize = 100;
        public Boolean includeNeverPurchased = true;
        /** Valores do CMDT recusados pela lista permitida (registrados no log do job). */
        public List<String> warnings = new List<String>();
    }

    /** Item (familia ou produto) elegivel a cruzada em um grupo, com a participacao do grupo. */
    public class Candidate {
        public String itemKey;
        public Id productId;
        public Decimal sharePercent;
        public Integer buyers;
        public Integer groupSize;
    }

    /** Fatos de uma conta x familia: ultimo mes fechado e meses completos da base. */
    public class FamilyFacts {
        public String family;
        public Decimal currentAmount = 0;
        public Decimal baseAmountTotal = 0;
        public Decimal currentQuantity = 0;
        public Decimal baseQuantityTotal = 0;
        /** Meses (aaaa-m) da base em que a conta comprou a familia. */
        public Set<String> baseMonths = new Set<String>();
        public Set<String> units = new Set<String>();
        public FamilyFacts(String family) {
            this.family = family;
        }
    }

    /** Fatos de uma conta, ja agregados pelo batch. */
    public class AccountFacts {
        public Id accountId;
        public String groupValue;
        public Date lastPurchase;
        public Map<String, FamilyFacts> families = new Map<String, FamilyFacts>();
        /** Itens (familia ou produto, conforme o nivel) comprados na janela recente da cruzada. */
        public Set<String> recentItems = new Set<String>();
    }

    /** Le o registro Default do CMDT; campos vazios ou registro ausente mantem o padrao. */
    public static Settings loadSettings() {
        return fromRecord(CommercialSignalSetting__mdt.getInstance('Default'));
    }

    @TestVisible
    private static Settings fromRecord(CommercialSignalSetting__mdt m) {
        Settings s = new Settings();
        if (m == null) {
            return s;
        }
        if (m.RecoveryDays__c != null) { s.recoveryDays = Integer.valueOf(m.RecoveryDays__c); }
        if (String.isNotBlank(m.PurchaseStatuses__c)) { s.purchaseStatuses = splitList(m.PurchaseStatuses__c); }
        if (m.VolumeWindowMonths__c != null && m.VolumeWindowMonths__c > 0) { s.volumeWindowMonths = Integer.valueOf(m.VolumeWindowMonths__c); }
        if (m.VolumeMinBaseMonths__c != null) { s.volumeMinBaseMonths = Integer.valueOf(m.VolumeMinBaseMonths__c); }
        s.volumeMinBaseMonths = Math.max(1, Math.min(s.volumeMinBaseMonths, s.volumeWindowMonths));
        if (m.VolumeThresholdPercent__c != null) { s.volumeThresholdPercent = m.VolumeThresholdPercent__c; }
        if (String.isNotBlank(m.VolumeDirections__c)) {
            String d = m.VolumeDirections__c.toLowerCase();
            s.directionDrop = d.contains('queda');
            s.directionRise = d.contains('alta');
        }
        s.volumeMetric = pick(m.VolumeMetric__c, new List<String>{ METRIC_VALUE, METRIC_QUANTITY, METRIC_BOTH }, METRIC_VALUE, 'VolumeMetric__c', s.warnings);
        s.purchaseDateField = pick(m.PurchaseDateField__c, ALLOWED_DATE_FIELDS, 'EffectiveDate', 'PurchaseDateField__c', s.warnings);
        s.familyField = pick(m.FamilyField__c, ALLOWED_FAMILY_FIELDS, 'Group__c', 'FamilyField__c', s.warnings);
        s.crossSellLevel = pick(m.CrossSellLevel__c, new List<String>{ LEVEL_FAMILY, LEVEL_PRODUCT }, LEVEL_FAMILY, 'CrossSellLevel__c', s.warnings);
        if (String.isNotBlank(m.CrossSellGroupField__c)) { s.crossSellGroupField = m.CrossSellGroupField__c.trim(); }
        for (String fam : splitList(m.CrossSellExcludedFamilies__c)) {
            s.crossSellExcludedFamilies.add(fam.toLowerCase());
        }
        if (m.CrossSellLookbackMonths__c != null) { s.crossSellLookbackMonths = Integer.valueOf(m.CrossSellLookbackMonths__c); }
        if (m.CrossSellRecentDays__c != null) { s.crossSellRecentDays = Integer.valueOf(m.CrossSellRecentDays__c); }
        if (m.CrossSellMinSharePercent__c != null) { s.crossSellMinSharePercent = m.CrossSellMinSharePercent__c; }
        if (m.CrossSellMinGroupSize__c != null) { s.crossSellMinGroupSize = Integer.valueOf(m.CrossSellMinGroupSize__c); }
        if (m.CrossSellMaxPerAccount__c != null) { s.crossSellMaxPerAccount = Integer.valueOf(m.CrossSellMaxPerAccount__c); }
        if (m.BatchSize__c != null && m.BatchSize__c > 0) { s.batchSize = Integer.valueOf(m.BatchSize__c); }
        s.includeNeverPurchased = m.IncludeNeverPurchased__c == true;
        return s;
    }

    /**
     * Valor do CMDT so vale se estiver na lista permitida (sem diferenciar maiusculas); devolve a grafia
     * canonica. Vazio usa o padrao em silencio; fora da lista usa o padrao e registra o aviso.
     */
    public static String pick(String raw, List<String> allowed, String fallback, String paramName, List<String> warnings) {
        if (String.isBlank(raw)) {
            return fallback;
        }
        for (String a : allowed) {
            if (a.equalsIgnoreCase(raw.trim())) {
                return a;
            }
        }
        if (warnings != null) {
            warnings.add(paramName + '="' + raw + '" fora da lista permitida; usando ' + fallback);
        }
        return fallback;
    }

    /** Campo de grupo vindo do CMDT so vale se existir em Account; senao volta para Sector__c. */
    public static String resolveGroupField(String configured) {
        if (String.isNotBlank(configured)) {
            Schema.SObjectField f = Schema.SObjectType.Account.fields.getMap().get(configured.trim().toLowerCase());
            if (f != null) {
                return f.getDescribe().getName();
            }
        }
        return 'Sector__c';
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

    /** Familia do produto; produto sem grupo entra como "Sem familia" (PA-26). */
    public static String familyKey(Object rawValue) {
        String v = groupKey(rawValue);
        return v == null ? NO_FAMILY : v;
    }

    public static String signalKey(Id accountId, String type, String suffix) {
        return accountId + '-' + type + '-' + (suffix == null ? '' : suffix.left(60));
    }

    // ---- Janelas de data -------------------------------------------------------------------------

    /** Primeiro dia do ultimo mes fechado. */
    public static Date currentMonthStart(Date today) {
        return today.toStartOfMonth().addMonths(-1);
    }

    /** Primeiro dia do mes corrente: limite superior (exclusivo) do ultimo mes fechado. */
    public static Date currentMonthEnd(Date today) {
        return today.toStartOfMonth();
    }

    /** Primeiro dia do primeiro mes completo da base. */
    public static Date baseStart(Date today, Integer baseMonths) {
        return currentMonthStart(today).addMonths(-baseMonths);
    }

    public static String monthKey(Integer year, Integer month) {
        return year + '-' + month;
    }

    public static Boolean isDateTimeField(String fieldName) {
        return fieldName == 'ActivatedDate';
    }

    /** Limite de data para o bind: Date, ou Datetime no inicio do dia quando o campo e Data/Hora. */
    public static Object bound(Date d, String fieldName) {
        if (isDateTimeField(fieldName)) {
            // meia-noite no fuso do usuario (e nao em GMT), o mesmo fuso que asDate e CALENDAR_MONTH usam
            return Datetime.newInstance(d.year(), d.month(), d.day());
        }
        return d;
    }

    public static Date asDate(Object v) {
        if (v == null) {
            return null;
        }
        // Date tambem passa em "instanceof Datetime": testar Date primeiro evita o deslocamento de fuso.
        if (v instanceof Date) {
            return (Date) v;
        }
        return ((Datetime) v).date();
    }

    /** Expressao SOQL do item da cruzada em OrderItem. So usa nomes ja validados pela lista permitida. */
    public static String itemExpression(Settings s) {
        return s.crossSellLevel == LEVEL_PRODUCT ? 'Product2Id' : 'Product2.' + s.familyField;
    }

    // ---- Regras ----------------------------------------------------------------------------------

    /** Recuperacao: mais de N dias desde a ultima compra valida (91 entra, 90 e 89 nao). */
    public static Boolean isRecovery(Date lastPurchase, Date today, Integer thresholdDays) {
        if (lastPurchase == null || today == null || thresholdDays == null) {
            return false;
        }
        return lastPurchase.daysBetween(today) > thresholdDays;
    }

    /**
     * Volume: devolve QuedaVolume, AltaVolume ou null, comparando o valor do ultimo mes fechado com a
     * media mensal da base. Base zero ou ausente nunca classifica (CA-07). Limite inclusivo (queda de
     * 20% ou mais). Comparacao exata, sem arredondar: |atual - base| * 100 >= limite * base.
     */
    public static String classifyVolume(Decimal baseMonthlyAverage, Decimal currentAmount, Settings s) {
        Decimal base = baseMonthlyAverage == null ? 0 : baseMonthlyAverage;
        Decimal cur = currentAmount == null ? 0 : currentAmount;
        if (base <= 0) {
            return null;
        }
        Decimal diffScaled = (cur - base) * 100;
        Decimal threshold = s.volumeThresholdPercent * base;
        if (s.directionDrop && -diffScaled >= threshold) {
            return TYPE_DROP;
        }
        if (s.directionRise && diffScaled >= threshold) {
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

    public static Boolean isMixedUnits(FamilyFacts ff) {
        return ff.units.size() > 1;
    }

    /** Media mensal sobre todos os meses da base (mes sem compra conta como zero). */
    public static Decimal monthlyAverage(Decimal total, Integer baseMonths) {
        return (total == null ? 0 : total) / baseMonths;
    }

    /**
     * Classificacao de uma familia: HistoricoInsuficiente quando comprou em menos meses da base que o
     * minimo; senao queda/alta pela metrica configurada. Quantidade de familia com unidades mistas nao
     * entra na comparacao.
     */
    public static String classifyFamily(FamilyFacts ff, Settings s) {
        if (ff.baseMonths.size() < s.volumeMinBaseMonths) {
            return TYPE_INSUFFICIENT;
        }
        String byAmount = classifyVolume(monthlyAverage(ff.baseAmountTotal, s.volumeWindowMonths), ff.currentAmount, s);
        String byQuantity = isMixedUnits(ff) ? null
            : classifyVolume(monthlyAverage(ff.baseQuantityTotal, s.volumeWindowMonths), ff.currentQuantity, s);
        if (s.volumeMetric == METRIC_QUANTITY) {
            return byQuantity;
        }
        if (s.volumeMetric == METRIC_BOTH) {
            return byAmount != null ? byAmount : byQuantity;
        }
        return byAmount;
    }

    /** Itens do grupo que passam nos limites de tamanho e participacao, do maior % para o menor. */
    public static List<Candidate> qualifyGroup(Integer groupSize, Map<String, Integer> buyersByItem, Settings s) {
        List<Candidate> result = new List<Candidate>();
        if (groupSize == null || groupSize < s.crossSellMinGroupSize || groupSize <= 0) {
            return result;
        }
        for (String itemKey : buyersByItem.keySet()) {
            if (itemKey == NO_FAMILY) {
                continue;
            }
            if (s.crossSellLevel == LEVEL_FAMILY && s.crossSellExcludedFamilies.contains(itemKey.toLowerCase())) {
                continue;
            }
            Integer buyers = buyersByItem.get(itemKey);
            // buyers/groupSize*100 >= limite, sem divisao: buyers*100 >= limite*groupSize
            if (buyers * 100 >= s.crossSellMinSharePercent * groupSize) {
                Candidate c = new Candidate();
                c.itemKey = itemKey;
                if (s.crossSellLevel == LEVEL_PRODUCT) {
                    c.productId = (Id) itemKey;
                }
                c.buyers = buyers;
                c.groupSize = groupSize;
                c.sharePercent = (Decimal.valueOf(buyers) * 100 / groupSize).setScale(1, RoundingMode.HALF_UP);
                result.add(c);
            }
        }
        sortCandidates(result);
        return result;
    }

    /** Ordena por participacao decrescente; empate pela chave do item, para resultado deterministico. */
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
        return a.itemKey < b.itemKey;
    }

    /** Todos os sinais de uma conta na data de calculo. Nao grava. */
    public static List<CommercialSignal__c> buildSignals(
        AccountFacts f, Date today, Settings s, Map<String, List<Candidate>> qualifiedByGroup
    ) {
        List<CommercialSignal__c> out = new List<CommercialSignal__c>();
        Boolean accountLevelSignal = false;
        if (f.lastPurchase == null) {
            if (s.includeNeverPurchased) {
                out.add(base(f, TYPE_NEVER, today, null,
                    'Nenhum pedido faturado (' + String.join(s.purchaseStatuses, ', ') + ').'));
            }
            accountLevelSignal = true;
        } else if (isRecovery(f.lastPurchase, today, s.recoveryDays)) {
            CommercialSignal__c r = base(f, TYPE_RECOVERY, today, null,
                'Ultima compra faturada em ' + f.lastPurchase.format() + ', ha ' + f.lastPurchase.daysBetween(today)
                + ' dias; limite de ' + s.recoveryDays + ' dias.');
            r.LastPurchaseDate__c = f.lastPurchase;
            r.DaysWithoutPurchase__c = f.lastPurchase.daysBetween(today);
            out.add(r);
            accountLevelSignal = true;
        }
        // PA-27: conta em Recuperacao ou NuncaComprou nao recebe sinal de volume (repetiria o mesmo alerta).
        if (!accountLevelSignal) {
            List<String> names = new List<String>(f.families.keySet());
            names.sort();
            for (String name : names) {
                CommercialSignal__c v = volumeSignal(f, f.families.get(name), today, s);
                if (v != null) {
                    out.add(v);
                }
            }
        }
        if (f.groupValue != null && qualifiedByGroup != null && qualifiedByGroup.containsKey(f.groupValue)) {
            Integer count = 0;
            for (Candidate c : qualifiedByGroup.get(f.groupValue)) {
                if (count >= s.crossSellMaxPerAccount) {
                    break;
                }
                if (f.recentItems.contains(c.itemKey)) {
                    continue;
                }
                Boolean byFamily = s.crossSellLevel == LEVEL_FAMILY;
                CommercialSignal__c x = base(f, TYPE_CROSS, today, c.itemKey,
                    c.sharePercent + '% das ' + c.groupSize + ' contas do segmento "' + f.groupValue
                    + '" compraram ' + (byFamily ? 'a familia ' + c.itemKey : 'o produto') + ' em '
                    + s.crossSellLookbackMonths + ' meses; esta conta nao comprou em '
                    + s.crossSellRecentDays + ' dias.');
                if (byFamily) {
                    x.ProductFamily__c = c.itemKey;
                } else {
                    x.Product__c = c.productId;
                }
                x.VariationPercent__c = c.sharePercent;
                x.LastPurchaseDate__c = f.lastPurchase;
                out.add(x);
                count++;
            }
        }
        return out;
    }

    private static CommercialSignal__c volumeSignal(AccountFacts f, FamilyFacts ff, Date today, Settings s) {
        String type = classifyFamily(ff, s);
        if (type == null) {
            return null;
        }
        Integer n = s.volumeWindowMonths;
        Decimal baseAvg = monthlyAverage(ff.baseAmountTotal, n);
        Boolean mixed = isMixedUnits(ff);
        String reason;
        if (type == TYPE_INSUFFICIENT) {
            reason = 'Familia ' + ff.family + ': comprou em ' + ff.baseMonths.size() + ' de ' + n
                + ' meses da base; minimo de ' + s.volumeMinBaseMonths + ' para comparar volume.';
        } else {
            reason = 'Familia ' + ff.family + ': ultimo mes fechado ' + ff.currentAmount.setScale(2)
                + '; media dos ' + n + ' meses anteriores ' + baseAvg.setScale(2) + '; limite de '
                + s.volumeThresholdPercent + '%.';
        }
        CommercialSignal__c v = base(f, type, today, ff.family, reason);
        v.ProductFamily__c = ff.family;
        v.BasePeriodAmount__c = baseAvg.setScale(2);
        v.CurrentPeriodAmount__c = ff.currentAmount.setScale(2);
        v.LastPurchaseDate__c = f.lastPurchase;
        if (mixed) {
            v.UnitOfMeasure__c = UNIT_MIXED;
        } else {
            String unit = UNIT_NONE;
            for (String u : ff.units) {
                unit = u;
            }
            v.UnitOfMeasure__c = unit;
            v.BasePeriodQuantity__c = monthlyAverage(ff.baseQuantityTotal, n).setScale(2);
            v.CurrentPeriodQuantity__c = ff.currentQuantity.setScale(2);
        }
        if (type != TYPE_INSUFFICIENT) {
            Boolean useQuantity = s.volumeMetric == METRIC_QUANTITY && !mixed;
            v.VariationPercent__c = useQuantity
                ? variationPercent(v.BasePeriodQuantity__c, v.CurrentPeriodQuantity__c)
                : variationPercent(baseAvg, ff.currentAmount);
        }
        return v;
    }

    private static CommercialSignal__c base(AccountFacts f, String type, Date today, String suffix, String reason) {
        CommercialSignal__c sig = new CommercialSignal__c();
        sig.Account__c = f.accountId;
        sig.Type__c = type;
        sig.CalculationDate__c = today;
        sig.SignalKey__c = signalKey(f.accountId, type, suffix);
        sig.Reason__c = reason.length() > 255 ? reason.substring(0, 255) : reason;
        return sig;
    }
}
