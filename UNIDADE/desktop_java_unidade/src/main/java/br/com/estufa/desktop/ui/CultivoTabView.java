package br.com.estufa.desktop.ui;

import br.com.estufa.desktop.model.Cultivo;
import br.com.estufa.desktop.model.SensorData;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.Node;
import javafx.scene.control.Label;
import javafx.scene.layout.*;
import javafx.scene.paint.Color;

import java.util.List;
import java.util.Locale;

/**
 * Aba que exibe os dados do cultivo habilitado:
 * - Configurações de limites (temp/umidade/solo)
 * - Leitura atual vs faixa ideal (com cor)
 * - Status geral da planta
 */
public class CultivoTabView extends VBox {

    private final Label nomeCultivo = new Label("Nenhum cultivo habilitado");
    private final Label tipoCultivo = new Label("-");

    // Temperatura
    private final Label tempAtual = new Label("-- °C");
    private final Label tempFaixa = new Label("-");
    private final Label tempStatus = new Label("-");

    // Umidade ar
    private final Label umidAtual = new Label("-- %");
    private final Label umidFaixa = new Label("-");
    private final Label umidStatus = new Label("-");

    // Umidade solo
    private final Label soloAtual = new Label("-- %");
    private final Label soloFaixa = new Label("-");
    private final Label soloStatus = new Label("-");

    // Status geral
    private final Label statusGeral = new Label("Aguardando dados...");

    public CultivoTabView() {
        setSpacing(12);
        setPadding(new Insets(14));

        getChildren().addAll(
                buildHeader(),
                buildSeparator(),
                buildLimitsGrid(),
                buildSeparator(),
                buildStatusGeral()
        );
    }

    private Node buildHeader() {
        nomeCultivo.setStyle("-fx-font-size: 20px; -fx-font-weight: bold;");
        tipoCultivo.setStyle("-fx-font-size: 13px; -fx-text-fill: #666;");

        VBox box = new VBox(4, nomeCultivo, tipoCultivo);
        box.setPadding(new Insets(4, 0, 4, 0));
        return box;
    }

    private Node buildSeparator() {
        Region sep = new Region();
        sep.setPrefHeight(1);
        sep.setStyle("-fx-background-color: #ddd;");
        return sep;
    }

    private Node buildLimitsGrid() {
        GridPane grid = new GridPane();
        grid.setHgap(16);
        grid.setVgap(10);
        grid.setPadding(new Insets(8, 0, 8, 0));

        // Cabeçalhos
        grid.add(bold("Variavel"), 0, 0);
        grid.add(bold("Faixa Ideal"), 1, 0);
        grid.add(bold("Leitura Atual"), 2, 0);
        grid.add(bold("Status"), 3, 0);

        // Temperatura
        grid.add(new Label("Temperatura"), 0, 1);
        grid.add(tempFaixa, 1, 1);
        grid.add(tempAtual, 2, 1);
        grid.add(tempStatus, 3, 1);

        // Umidade ar
        grid.add(new Label("Umidade do ar"), 0, 2);
        grid.add(umidFaixa, 1, 2);
        grid.add(umidAtual, 2, 2);
        grid.add(umidStatus, 3, 2);

        // Solo
        grid.add(new Label("Umidade do solo"), 0, 3);
        grid.add(soloFaixa, 1, 3);
        grid.add(soloAtual, 2, 3);
        grid.add(soloStatus, 3, 3);

        return grid;
    }

    private Node buildStatusGeral() {
        statusGeral.setStyle("-fx-font-size: 14px; -fx-font-weight: bold;");
        VBox box = new VBox(6,
                new Label("Condicao geral do cultivo:"),
                statusGeral
        );
        box.setPadding(new Insets(4));
        box.setStyle("-fx-background-color: #f5f5f5; -fx-background-radius: 6; -fx-padding: 10;");
        return box;
    }

    /**
     * Atualiza a aba com os dados do cultivo e a última leitura disponível.
     */
    public void update(Cultivo cultivo, List<SensorData> amostras) {
        if (cultivo == null) {
            nomeCultivo.setText("Nenhum cultivo habilitado");
            tipoCultivo.setText("Habilite um cultivo no aplicativo mobile.");
            tempFaixa.setText("-");
            umidFaixa.setText("-");
            soloFaixa.setText("-");
            tempAtual.setText("--");
            umidAtual.setText("--");
            soloAtual.setText("--");
            tempStatus.setText("-");
            umidStatus.setText("-");
            soloStatus.setText("-");
            statusGeral.setText("Sem cultivo configurado.");
            statusGeral.setTextFill(Color.GRAY);
            return;
        }

        nomeCultivo.setText(cultivo.getNome());
        tipoCultivo.setText("Tipo: " + (cultivo.getTipo() == null ? "-" : cultivo.getTipo()));

        tempFaixa.setText(String.format(Locale.US, "%.1f – %.1f °C", cultivo.getTemperaturaMinima(), cultivo.getTemperaturaMaxima()));
        umidFaixa.setText(String.format(Locale.US, "%.1f – %.1f %%", cultivo.getUmidadeMinima(), cultivo.getUmidadeMaxima()));
        soloFaixa.setText(String.format(Locale.US, "%.1f – %.1f %%", cultivo.getUmidadeSoloMinima(), cultivo.getUmidadeSoloMaxima()));

        if (amostras == null || amostras.isEmpty()) {
            tempAtual.setText("--");
            umidAtual.setText("--");
            soloAtual.setText("--");
            tempStatus.setText("-");
            umidStatus.setText("-");
            soloStatus.setText("-");
            statusGeral.setText("Sem leituras recentes.");
            statusGeral.setTextFill(Color.GRAY);
            return;
        }

        // Última leitura
        SensorData ultima = amostras.get(amostras.size() - 1);
        double t = ultima.getTemperatura();
        double u = ultima.getUmidade();
        double s = ultima.umidadeSoloOuZero();

        tempAtual.setText(String.format(Locale.US, "%.1f °C", t));
        umidAtual.setText(String.format(Locale.US, "%.1f %%", u));
        soloAtual.setText(String.format(Locale.US, "%.1f %%", s));

        boolean tempOk = t >= cultivo.getTemperaturaMinima() && t <= cultivo.getTemperaturaMaxima();
        boolean umidOk = u >= cultivo.getUmidadeMinima() && u <= cultivo.getUmidadeMaxima();
        boolean soloOk = s >= cultivo.getUmidadeSoloMinima() && s <= cultivo.getUmidadeSoloMaxima();

        applyStatus(tempStatus, tempOk, t < cultivo.getTemperaturaMinima() ? "Abaixo da faixa" : "Acima da faixa");
        applyStatus(umidStatus, umidOk, u < cultivo.getUmidadeMinima() ? "Abaixo da faixa" : "Acima da faixa");
        applyStatus(soloStatus, soloOk, s < cultivo.getUmidadeSoloMinima() ? "Solo seco" : "Solo encharcado");

        long problemCount = (tempOk ? 0 : 1) + (umidOk ? 0 : 1) + (soloOk ? 0 : 1);
        if (problemCount == 0) {
            statusGeral.setText("Otimo — todas as variaveis dentro da faixa ideal.");
            statusGeral.setTextFill(Color.web("#0f8a3d"));
        } else if (problemCount == 1) {
            statusGeral.setText("Atencao — 1 variavel fora da faixa ideal. Verificar.");
            statusGeral.setTextFill(Color.web("#eaaa08"));
        } else {
            statusGeral.setText("Critico — " + problemCount + " variaveis fora da faixa. Acao imediata necessaria.");
            statusGeral.setTextFill(Color.web("#b42318"));
        }
    }

    private void applyStatus(Label label, boolean ok, String mensagemProblema) {
        if (ok) {
            label.setText("Ideal");
            label.setTextFill(Color.web("#0f8a3d"));
        } else {
            label.setText(mensagemProblema);
            label.setTextFill(Color.web("#b42318"));
        }
    }

    private Label bold(String text) {
        Label l = new Label(text);
        l.setStyle("-fx-font-weight: bold;");
        return l;
    }
}
