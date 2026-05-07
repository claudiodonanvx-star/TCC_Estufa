package br.com.estufa.desktop.model;

public enum UserRole {
    ADMIN("Administrador"),
    TECNICO("Tecnico"),
    OPERADOR("Operador"),
    CLIENTE("Cliente");

    private final String label;

    UserRole(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }
}
