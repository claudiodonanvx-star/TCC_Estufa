package br.com.estufa.desktop.model;

public enum PeriodType {
    DIARIO("Diario", 4320, 24),
    SEMANAL("Semanal", 30240, 21),
    MENSAL("Mensal", 129600, 30);

    private final String label;
    private final int sampleWindow;
    private final int buckets;

    PeriodType(String label, int sampleWindow, int buckets) {
        this.label = label;
        this.sampleWindow = sampleWindow;
        this.buckets = buckets;
    }

    public String getLabel() {
        return label;
    }

    public int getSampleWindow() {
        return sampleWindow;
    }

    public int getBuckets() {
        return buckets;
    }

    @Override
    public String toString() {
        return label;
    }
}
