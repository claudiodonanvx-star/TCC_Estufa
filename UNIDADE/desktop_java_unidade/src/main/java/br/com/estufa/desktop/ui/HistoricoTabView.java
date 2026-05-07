package br.com.estufa.desktop.ui;

import br.com.estufa.desktop.model.RelatorioDiario;
import br.com.estufa.desktop.model.UserRole;
import javafx.collections.FXCollections;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.chart.*;
import javafx.scene.control.*;
import javafx.scene.layout.*;

import java.util.List;
import java.util.Locale;
import java.util.function.Consumer;

/**
 * Aba de histórico consolidado:
 * - Gráfico de linha com temperatura/umidade/solo por data (dados reais da tabela relatorio_diario)
 * - Tabela com todos os campos
 * - Botão "Consolidar D-1 agora" (admin)
 */
public class HistoricoTabView extends VBox {

    private final UserRole userRole;
    private final Consumer<String> onConsolidar; // aceita null para rodar D-1

    private final ComboBox<String> periodoCombo = new ComboBox<>();
    private final LineChart<String, Number> lineChart;
    private final TableView<RelatorioDiario> table = new TableView<>();
    private final Label statusLabel = new Label("Sem dados consolidados ainda. Execute 'Consolidar D-1 agora' ou aguarde o job noturno (00:10).");

    public HistoricoTabView(UserRole userRole, Consumer<String> onConsolidar) {
        this.userRole = userRole;
        this.onConsolidar = onConsolidar;

        setSpacing(10);
        setPadding(new Insets(12));

        CategoryAxis xAxis = new CategoryAxis();
        NumberAxis yAxis = new NumberAxis();
        lineChart = new LineChart<>(xAxis, yAxis);
        lineChart.setTitle("Historico consolidado por dia");
        lineChart.setAnimated(false);
        lineChart.setPrefHeight(300);

        getChildren().addAll(buildToolbar(), statusLabel, lineChart, buildTable());
        VBox.setVgrow(lineChart, Priority.ALWAYS);
        VBox.setVgrow(table, Priority.ALWAYS);
    }

    private HBox buildToolbar() {
        periodoCombo.setItems(FXCollections.observableArrayList("Semanal (7 dias)", "Mensal (30 dias)", "Anual (365 dias)"));
        periodoCombo.getSelectionModel().select(1);

        HBox toolbar = new HBox(10);
        toolbar.setAlignment(Pos.CENTER_LEFT);
        toolbar.getChildren().addAll(new Label("Periodo:"), periodoCombo);

        if (userRole == UserRole.ADMIN || userRole == UserRole.TECNICO) {
            Button consolidarBtn = new Button("Consolidar D-1 agora");
            consolidarBtn.setStyle("-fx-background-color: #1a56db; -fx-text-fill: white;");
            consolidarBtn.setOnAction(e -> onConsolidar.accept(null));
            toolbar.getChildren().add(consolidarBtn);
        }

        return toolbar;
    }

    private TableView<RelatorioDiario> buildTable() {
        table.setPlaceholder(new Label("Sem dados consolidados."));
        table.setPrefHeight(220);

        TableColumn<RelatorioDiario, String> dataCol = new TableColumn<>("Data");
        dataCol.setCellValueFactory(c -> new javafx.beans.property.SimpleStringProperty(c.getValue().getDataRef()));
        dataCol.setPrefWidth(110);

        TableColumn<RelatorioDiario, Number> tMediaCol = new TableColumn<>("Temp Media");
        tMediaCol.setCellValueFactory(c -> new javafx.beans.property.SimpleDoubleProperty(c.getValue().getTempMedia()));

        TableColumn<RelatorioDiario, Number> tMinCol = new TableColumn<>("Temp Min");
        tMinCol.setCellValueFactory(c -> new javafx.beans.property.SimpleDoubleProperty(c.getValue().getTempMinima()));

        TableColumn<RelatorioDiario, Number> tMaxCol = new TableColumn<>("Temp Max");
        tMaxCol.setCellValueFactory(c -> new javafx.beans.property.SimpleDoubleProperty(c.getValue().getTempMaxima()));

        TableColumn<RelatorioDiario, Number> uMediaCol = new TableColumn<>("Umid Media");
        uMediaCol.setCellValueFactory(c -> new javafx.beans.property.SimpleDoubleProperty(c.getValue().getUmidadeMedia()));

        TableColumn<RelatorioDiario, Number> sMediaCol = new TableColumn<>("Solo Media");
        sMediaCol.setCellValueFactory(c -> new javafx.beans.property.SimpleDoubleProperty(c.getValue().getSoloMedia()));

        TableColumn<RelatorioDiario, Number> leiturasCol = new TableColumn<>("Leituras");
        leiturasCol.setCellValueFactory(c -> new javafx.beans.property.SimpleIntegerProperty(c.getValue().getTotalLeituras()));

        table.getColumns().setAll(dataCol, tMediaCol, tMinCol, tMaxCol, uMediaCol, sMediaCol, leiturasCol);

        return table;
    }

    public String getSelectedPeriodo() {
        int idx = periodoCombo.getSelectionModel().getSelectedIndex();
        if (idx == 0) return "semanal";
        if (idx == 2) return "anual";
        return "mensal";
    }

    public ComboBox<String> getPeriodoCombo() {
        return periodoCombo;
    }

    public void applyData(List<RelatorioDiario> dados) {
        if (dados == null || dados.isEmpty()) {
            statusLabel.setText("Sem dados consolidados ainda. Execute 'Consolidar D-1 agora' ou aguarde o job noturno (00:10).");
            statusLabel.setVisible(true);
            lineChart.getData().clear();
            table.getItems().clear();
            return;
        }

        statusLabel.setVisible(false);

        // Gráfico
        lineChart.getData().clear();

        XYChart.Series<String, Number> tempSeries = new XYChart.Series<>();
        tempSeries.setName("Temp media (C)");

        XYChart.Series<String, Number> umidSeries = new XYChart.Series<>();
        umidSeries.setName("Umidade media (%)");

        XYChart.Series<String, Number> soloSeries = new XYChart.Series<>();
        soloSeries.setName("Solo media (%)");

        for (RelatorioDiario r : dados) {
            String label = r.getDataRef() != null ? r.getDataRef().substring(5) : ""; // MM-DD
            tempSeries.getData().add(new XYChart.Data<>(label, r.getTempMedia()));
            umidSeries.getData().add(new XYChart.Data<>(label, r.getUmidadeMedia()));
            soloSeries.getData().add(new XYChart.Data<>(label, r.getSoloMedia()));
        }

        lineChart.getData().addAll(tempSeries, umidSeries, soloSeries);

        // Tabela
        table.setItems(FXCollections.observableArrayList(dados));
    }

    public void showConsolidarResult(String mensagem) {
        Alert alert = new Alert(Alert.AlertType.INFORMATION);
        alert.setHeaderText("Consolidacao concluida");
        alert.setContentText(mensagem);
        alert.showAndWait();
    }
}
