public class ParetoAnalysis {

    public class ParetoResult {
        public String item { get; set; }
        public Decimal individualParticipation { get; set; }
        public Decimal cumulativeParticipation { get; set; }
        public String type { get; set; } // Adicionando o tipo

        public ParetoResult(String item, Decimal individualParticipation, Decimal cumulativeParticipation, String type) {
            this.item = item;
            this.individualParticipation = individualParticipation;
            this.cumulativeParticipation = cumulativeParticipation;
            this.type = type; // Inicializando o tipo
        }
    }

    public static List<ParetoResult> calculatePareto(List<Decimal> values, List<String> items) {
        if (values.size() != items.size() || values.isEmpty()) {
            throw new IllegalArgumentException('As listas de valores e itens devem ter o mesmo tamanho e não podem estar vazias.');
        }

        Decimal totalValue = 0;
        for (Decimal value : values) {
            totalValue += value;
        }

        List<ParetoResult> results = new List<ParetoResult>();
        Decimal cumulativeValue = 0;

        for (Integer i = 0; i < values.size(); i++) {
            Decimal individualValue = values[i];
            Decimal individualParticipation = totalValue > 0 ? (individualValue / totalValue) * 100 : 0;
            cumulativeValue += individualValue;
            Decimal cumulativeParticipation = totalValue > 0 ? (cumulativeValue / totalValue) * 100 : 0;

            // Determinando o tipo com base na participação acumulada
            String type;
            if (cumulativeParticipation <= 80) {
                type = 'A';
            } else if (cumulativeParticipation > 80 && cumulativeParticipation < 95) {
                type = 'B';
            } else {
                type = 'C';
            }

            results.add(new ParetoResult(items[i], individualParticipation, cumulativeParticipation, type));
        }

        return results;
    }
}