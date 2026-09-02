package br.com.estufa.desktop.ui;

import java.util.ArrayList;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.function.BiConsumer;
import java.util.function.Consumer;

import com.fasterxml.jackson.databind.JsonNode;

import br.com.estufa.desktop.model.Cultivo;
import br.com.estufa.desktop.model.PeriodData;
import br.com.estufa.desktop.model.PeriodType;
import br.com.estufa.desktop.model.RelatorioDiario;
import br.com.estufa.desktop.model.SensorData;
import br.com.estufa.desktop.model.UserRole;
import javafx.animation.Animation;
import javafx.animation.KeyFrame;
import javafx.animation.Timeline;
import javafx.collections.FXCollections;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.Node;
import javafx.scene.chart.BarChart;
import javafx.scene.chart.CategoryAxis;
import javafx.scene.chart.LineChart;
import javafx.scene.chart.NumberAxis;
import javafx.scene.chart.PieChart;
import javafx.scene.chart.XYChart;
import javafx.scene.control.Alert;
import javafx.scene.control.Button;
import javafx.scene.control.ComboBox;
import javafx.scene.control.Label;
import javafx.scene.control.ListView;
import javafx.scene.control.SplitPane;
import javafx.scene.control.Tab;
import javafx.scene.control.TabPane;
import javafx.scene.control.TableColumn;
import javafx.scene.control.TableView;
import javafx.scene.control.TextArea;
import javafx.scene.control.Tooltip;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.GridPane;
import javafx.scene.layout.HBox;
import javafx.scene.layout.Priority;
import javafx.scene.layout.VBox;
import javafx.scene.paint.Color;
import javafx.util.Duration;

public class MainDashboardView extends BorderPane {

    private final String username;
    private final UserRole userRole;

    private final Label statusApi = new Label("API: verificando...");
    private final Label infoCultivo = new Label("Cultivo: -");
    private final Label infoAmostras = new Label("Amostras: 0");
    private final Label alertaBadge = new Label();

    private final Label kpiTemp = new Label("0.0");
    private final Label kpiUmidade = new Label("0.0");
    private final Label kpiSolo = new Label("0.0");
    private final Label kpiIdeal = new Label("0.0%");
    private final Label kpiAlerta = new Label("0");
    private final Label kpiSaude = new Label("0");

    private final LineChart<String, Number> overviewLineChart;
    private final PieChart overviewPieChart = new PieChart();
    private final BarChart<String, Number> overviewBarChart;

    private final Map<PeriodType, PeriodPanel> periodPanels = new EnumMap<>(PeriodType.class);

    private final ComboBox<PeriodType> reportsPeriod = new ComboBox<>();
    private final TextArea reportsSummary = new TextArea();
    private final ListView<String> reportsRecommendations = new ListView<>();

    private final BiConsumer<PeriodType, String> exportCallback;

    private CultivoTabView cultivoTabView;
    private HistoricoTabView historicoTabView;
    private AtuadoresTabView atuadoresTabView;
    private List<SensorData> lastSamples = List.of();
    private Cultivo lastCultivo;

    private Timeline refreshTimer;
    private final Label refreshCountdown = new Label();
    private int refreshIntervalSeconds = 60;

    public MainDashboardView(String username, UserRole userRole, Runnable refreshCallback,
                             BiConsumer<PeriodType, String> exportCallback,
                             Consumer<String> onConsolidar,
                             Consumer<Boolean> onToggleModoAutomatico,
                             BiConsumer<String, Integer> onAcionarAtuador) {
        this.username = username;
        this.userRole = userRole;
        this.exportCallback = exportCallback;

        setPadding(new Insets(12));

        CategoryAxis lineX = new CategoryAxis();
        NumberAxis lineY = new NumberAxis();
        overviewLineChart = new LineChart<>(lineX, lineY);
        overviewLineChart.setTitle("Tendencia de leituras");
        overviewLineChart.setAnimated(false);

        CategoryAxis alertX = new CategoryAxis();
        NumberAxis alertY = new NumberAxis();
        overviewBarChart = new BarChart<>(alertX, alertY);
        overviewBarChart.setTitle("Alertas por bloco");
        overviewBarChart.setAnimated(false);

        cultivoTabView = new CultivoTabView();
        historicoTabView = new HistoricoTabView(userRole, onConsolidar);
        atuadoresTabView = new AtuadoresTabView(onToggleModoAutomatico, onAcionarAtuador);

        setTop(buildHeader(refreshCallback));
        setCenter(buildTabs());

        startRefreshTimer(refreshCallback);
    }

    private Node buildHeader(Runnable refreshCallback) {
        Label title = new Label("Estufa Smart - Desktop Inteligente");
        title.getStyleClass().add("title");

        Label subtitle = new Label("Dashboard de monitoramento unificado para o produto cliente");
        subtitle.getStyleClass().add("subtitle");

        Button refreshBtn = new Button("Atualizar agora");
        refreshBtn.setOnAction(event -> {
            restartRefreshTimer(refreshCallback);
            refreshCallback.run();
        });

        // Controle de intervalo de refresh
        ComboBox<Integer> intervalCombo = new ComboBox<>();
        intervalCombo.getItems().addAll(15, 30, 60, 120, 300);
        intervalCombo.setValue(refreshIntervalSeconds);
        intervalCombo.setTooltip(new Tooltip("Intervalo de atualizacao automatica (segundos)"));
        intervalCombo.valueProperty().addListener((obs, old, novo) -> {
            refreshIntervalSeconds = novo;
            restartRefreshTimer(refreshCallback);
        });

        refreshCountdown.getStyleClass().add("badge");
        refreshCountdown.setStyle("-fx-text-fill: #475467;");

        statusApi.getStyleClass().add("badge");
        infoCultivo.getStyleClass().add("badge");
        infoAmostras.getStyleClass().add("badge");
        Label infoUser = new Label("Usuario: " + username + " (" + userRole.getLabel() + ")");
        infoUser.getStyleClass().add("badge");

        alertaBadge.setVisible(false);
        alertaBadge.setStyle("-fx-background-color: #b42318; -fx-text-fill: white; -fx-padding: 6 14 6 14; -fx-background-radius: 12; -fx-font-weight: bold;");

        HBox headerTitle = new HBox(10, title);
        headerTitle.setAlignment(Pos.CENTER_LEFT);

        VBox left = new VBox(6, headerTitle, subtitle);
        left.setAlignment(Pos.CENTER_LEFT);

        HBox chips = new HBox(8, statusApi, infoCultivo, infoAmostras, infoUser);
        chips.setAlignment(Pos.CENTER_RIGHT);

        HBox right = new HBox(10, alertaBadge, chips, new Label("Auto:"), intervalCombo, new Label("s"), refreshCountdown, refreshBtn);
        right.setAlignment(Pos.CENTER_RIGHT);
        right.getStyleClass().add("header-actions");

        BorderPane pane = new BorderPane();
        pane.setLeft(left);
        pane.setRight(right);
        pane.getStyleClass().add("dashboard-header");
        pane.setPadding(new Insets(10, 0, 16, 0));
        return pane;
    }

    private Node buildTabs() {
        TabPane tabPane = new TabPane();

        Tab overview = new Tab("Visao Geral", buildOverview());
        overview.setClosable(false);
        tabPane.getTabs().add(overview);

        for (PeriodType period : allowedPeriods()) {
            PeriodPanel panel = new PeriodPanel(period);
            periodPanels.put(period, panel);
            Tab tab = new Tab(period.getLabel(), panel);
            tab.setClosable(false);
            tabPane.getTabs().add(tab);
        }

        Tab cultivoTab = new Tab("Cultivo", cultivoTabView);
        cultivoTab.setClosable(false);
        tabPane.getTabs().add(cultivoTab);

        Tab historicoTab = new Tab("Historico Consolidado", historicoTabView);
        historicoTab.setClosable(false);
        tabPane.getTabs().add(historicoTab);

        Tab atuadoresTab = new Tab("Reles", atuadoresTabView);
        atuadoresTab.setClosable(false);
        tabPane.getTabs().add(atuadoresTab);

        if (canViewReports()) {
            Tab reports = new Tab("Relatorios Inteligentes", buildReportsTab());
            reports.setClosable(false);
            tabPane.getTabs().add(reports);
        }

        return tabPane;
    }

    private Node buildOverview() {
        VBox root = new VBox(14);
        root.setPadding(new Insets(12));
        root.getStyleClass().add("overview-section");

        GridPane cards = new GridPane();
        cards.setHgap(12);
        cards.setVgap(12);
        cards.setPadding(new Insets(4, 0, 4, 0));
        cards.getStyleClass().add("overview-card-grid");
        cards.add(card("Temp média", kpiTemp), 0, 0);
        cards.add(card("Umidade média", kpiUmidade), 1, 0);
        cards.add(card("Umidade solo", kpiSolo), 2, 0);
        cards.add(card("Tempo ideal", kpiIdeal), 0, 1);
        cards.add(card("Alertas", kpiAlerta), 1, 1);
        cards.add(card("Índice saúde", kpiSaude), 2, 1);

        SplitPane split = new SplitPane();
        split.setDividerPositions(0.62);
        split.getStyleClass().add("overview-split");

        overviewLineChart.setCreateSymbols(false);
        overviewLineChart.setLegendVisible(true);
        overviewBarChart.setBarGap(6);
        overviewBarChart.setCategoryGap(18);
        overviewPieChart.setLabelsVisible(true);
        overviewPieChart.setClockwise(true);

        VBox left = new VBox(14, wrapChart(overviewLineChart), wrapChart(overviewBarChart));
        left.setPadding(new Insets(4));
        VBox right = new VBox(14, wrapChart(overviewPieChart));
        right.setPadding(new Insets(4));

        VBox.setVgrow(overviewLineChart, Priority.ALWAYS);
        VBox.setVgrow(overviewBarChart, Priority.ALWAYS);
        VBox.setVgrow(overviewPieChart, Priority.ALWAYS);

        split.getItems().addAll(left, right);

        root.getChildren().addAll(cards, split);
        VBox.setVgrow(split, Priority.ALWAYS);
        return root;
    }

    private Node wrapChart(Node chart) {
        VBox wrapper = new VBox(chart);
        wrapper.getStyleClass().add("chart-card");
        wrapper.setPadding(new Insets(16));
        wrapper.setMinHeight(270);
        wrapper.setMaxWidth(Double.MAX_VALUE);
        return wrapper;
    }

    private Node buildReportsTab() {
        VBox root = new VBox(10);
        root.setPadding(new Insets(8));

        List<PeriodType> allowed = allowedPeriods();
        reportsPeriod.setItems(FXCollections.observableArrayList(allowed));
        if (!allowed.isEmpty()) {
            reportsPeriod.getSelectionModel().select(allowed.get(0));
        }
        reportsPeriod.valueProperty().addListener((obs, oldVal, newVal) -> updateReportsPane(newVal));

        Button exportCsv = new Button("Exportar CSV");
        exportCsv.setDisable(!canExportCsv());
        exportCsv.setOnAction(event -> exportCallback.accept(reportsPeriod.getValue(), "csv"));

        Button exportPdf = new Button("Exportar PDF");
        exportPdf.setDisable(!canExportPdf());
        exportPdf.setOnAction(event -> exportCallback.accept(reportsPeriod.getValue(), "pdf"));

        HBox actions = new HBox(10, new Label("Periodo:"), reportsPeriod, exportCsv, exportPdf);
        actions.setAlignment(Pos.CENTER_LEFT);

        reportsSummary.setEditable(false);
        reportsSummary.setWrapText(true);
        reportsSummary.setPrefRowCount(8);

        reportsRecommendations.setPrefHeight(180);

        root.getChildren().addAll(
                actions,
                new Label("Resumo automatico"),
                reportsSummary,
                new Label("Recomendacoes"),
                reportsRecommendations
        );
        return root;
    }

    private VBox card(String title, Label value) {
        Label titleLabel = new Label(title);
        titleLabel.getStyleClass().add("card-title");
        value.getStyleClass().add("card-value");

        VBox box = new VBox(4, titleLabel, value);
        box.setPadding(new Insets(10));
        box.getStyleClass().add("kpi-card");
        box.setPrefWidth(170);
        return box;
    }

    public void applyData(Map<PeriodType, PeriodData> dataByPeriod, Cultivo cultivo, boolean apiOnline, int totalSamples,
                          List<SensorData> samples) {
        statusApi.setText(apiOnline ? "API online" : "API offline");
        statusApi.setTextFill(apiOnline ? Color.web("#0f8a3d") : Color.web("#b42318"));

        if (cultivo != null) {
            infoCultivo.setText("Cultivo: " + cultivo.getNome());
        } else {
            infoCultivo.setText("Cultivo: nao habilitado");
        }
        infoAmostras.setText("Amostras: " + totalSamples);

        this.lastSamples = samples != null ? samples : List.of();
        this.lastCultivo = cultivo;

        cultivoTabView.update(cultivo, lastSamples);

        PeriodData daily = dataByPeriod.getOrDefault(PeriodType.DIARIO, null);
        if (daily != null) {
            updateOverview(daily);
            // Badge de alerta
            int alertas = daily.getKpis().alertasCriticos();
            double ideal = daily.getKpis().tempoFaixaIdealPct();
            if (alertas > 0 || ideal < 70) {
                String msg = alertas > 0
                        ? "\u26a0 " + alertas + " alerta(s) critico(s)"
                        : "\u26a0 Tempo ideal baixo (" + String.format("%.0f%%", ideal) + ")";
                alertaBadge.setText(msg);
                alertaBadge.setStyle(alertas > 5
                        ? "-fx-background-color: #b42318; -fx-text-fill: white; -fx-padding: 4 10 4 10; -fx-background-radius: 8; -fx-font-weight: bold;"
                        : "-fx-background-color: #eaaa08; -fx-text-fill: #333; -fx-padding: 4 10 4 10; -fx-background-radius: 8; -fx-font-weight: bold;");
                alertaBadge.setVisible(true);
            } else {
                alertaBadge.setVisible(false);
            }
        }

        periodPanels.forEach((period, panel) -> {
            PeriodData periodData = dataByPeriod.get(period);
            if (periodData != null) {
                panel.apply(periodData);
            }
        });

        updateReportsPane(reportsPeriod.getValue());
    }

    // Manter compatibilidade — versão sem samples (legado)
    public void applyData(Map<PeriodType, PeriodData> dataByPeriod, Cultivo cultivo, boolean apiOnline, int totalSamples) {
        applyData(dataByPeriod, cultivo, apiOnline, totalSamples, List.of());
    }

    public void applyHistorico(List<RelatorioDiario> dados) {
        historicoTabView.applyData(dados);
    }

    public void showConsolidarResult(String mensagem) {
        historicoTabView.showConsolidarResult(mensagem);
    }

    public HistoricoTabView getHistoricoTabView() {
        return historicoTabView;
    }

    public void applyAtuadores(JsonNode estado) {
        atuadoresTabView.applyEstado(estado);
    }

    private void startRefreshTimer(Runnable refreshCallback) {
        int[] secondsLeft = {refreshIntervalSeconds};
        refreshCountdown.setText("Prox: " + refreshIntervalSeconds + "s");
        refreshTimer = new Timeline(
                new KeyFrame(Duration.seconds(1), e -> {
                    secondsLeft[0]--;
                    refreshCountdown.setText("Prox: " + secondsLeft[0] + "s");
                    if (secondsLeft[0] <= 0) {
                        secondsLeft[0] = refreshIntervalSeconds;
                        refreshCallback.run();
                    }
                })
        );
        refreshTimer.setCycleCount(Animation.INDEFINITE);
        refreshTimer.play();
    }

    private void restartRefreshTimer(Runnable refreshCallback) {
        if (refreshTimer != null) {
            refreshTimer.stop();
        }
        startRefreshTimer(refreshCallback);
    }

    public void showError(String message) {
        Alert alert = new Alert(Alert.AlertType.ERROR);
        alert.setHeaderText("Falha ao atualizar dashboard");
        alert.setContentText(message);
        alert.showAndWait();
    }

    private void updateOverview(PeriodData data) {
        kpiTemp.setText(String.format("%.1f C", data.getKpis().temperaturaMedia()));
        kpiUmidade.setText(String.format("%.1f %%", data.getKpis().umidadeMedia()));
        kpiSolo.setText(String.format("%.1f %%", data.getKpis().umidadeSoloMedia()));
        kpiIdeal.setText(String.format("%.1f %%", data.getKpis().tempoFaixaIdealPct()));
        kpiAlerta.setText(String.valueOf(data.getKpis().alertasCriticos()));
        kpiSaude.setText(String.format("%.1f", data.getKpis().indiceSaude()));

        overviewLineChart.getData().clear();
        XYChart.Series<String, Number> temp = new XYChart.Series<>();
        temp.setName("Temperatura");
        XYChart.Series<String, Number> umidade = new XYChart.Series<>();
        umidade.setName("Umidade");
        XYChart.Series<String, Number> solo = new XYChart.Series<>();
        solo.setName("Umidade solo");

        for (PeriodData.SeriesPoint point : data.getLinePoints()) {
            temp.getData().add(new XYChart.Data<>(point.label(), point.temperatura()));
            umidade.getData().add(new XYChart.Data<>(point.label(), point.umidade()));
            solo.getData().add(new XYChart.Data<>(point.label(), point.umidadeSolo()));
        }
        overviewLineChart.getData().addAll(temp, umidade, solo);

        overviewBarChart.getData().clear();
        XYChart.Series<String, Number> alertSeries = new XYChart.Series<>();
        alertSeries.setName("Alertas");
        for (PeriodData.SeriesPoint point : data.getAlertPoints()) {
            alertSeries.getData().add(new XYChart.Data<>(point.label(), point.temperatura()));
        }
        overviewBarChart.getData().add(alertSeries);

        double ideal = data.getKpis().tempoFaixaIdealPct();
        double fora = Math.max(0.0, 100.0 - ideal);
        overviewPieChart.setData(FXCollections.observableArrayList(
                new PieChart.Data("Faixa ideal", ideal),
                new PieChart.Data("Fora da faixa", fora)
        ));
    }

    private void updateReportsPane(PeriodType selectedPeriod) {
        if (!canViewReports()) {
            reportsSummary.setText("Perfil sem acesso a relatorios inteligentes.");
            reportsRecommendations.setItems(FXCollections.observableArrayList());
            return;
        }

        if (selectedPeriod == null) {
            return;
        }

        PeriodPanel panel = periodPanels.get(selectedPeriod);
        if (panel == null || panel.lastData == null) {
            reportsSummary.setText("Sem dados para o periodo selecionado.");
            reportsRecommendations.setItems(FXCollections.observableArrayList());
            return;
        }

        reportsSummary.setText(panel.lastData.getSummary());
        reportsRecommendations.setItems(FXCollections.observableArrayList(panel.lastData.getRecommendations()));
    }

    public PeriodData getPeriodForExport(PeriodType periodType) {
        PeriodPanel panel = periodPanels.get(periodType);
        return panel == null ? null : panel.lastData;
    }

    private List<PeriodType> allowedPeriods() {
        List<PeriodType> periods = new ArrayList<>();
        switch (userRole) {
            case ADMIN, TECNICO -> periods.addAll(List.of(PeriodType.DIARIO, PeriodType.SEMANAL, PeriodType.MENSAL));
            case OPERADOR -> periods.add(PeriodType.DIARIO);
            case CLIENTE -> periods.addAll(List.of(PeriodType.SEMANAL, PeriodType.MENSAL));
        }
        return periods;
    }

    private boolean canViewReports() {
        return userRole == UserRole.ADMIN || userRole == UserRole.TECNICO || userRole == UserRole.CLIENTE;
    }

    private boolean canExportCsv() {
        return userRole == UserRole.ADMIN || userRole == UserRole.TECNICO || userRole == UserRole.CLIENTE;
    }

    private boolean canExportPdf() {
        return userRole == UserRole.ADMIN || userRole == UserRole.CLIENTE;
    }

    private static class PeriodPanel extends BorderPane {
        private final PeriodType period;

        private final Label temp = new Label("0.0 C");
        private final Label umid = new Label("0.0 %");
        private final Label solo = new Label("0.0 %");
        private final Label ideal = new Label("0.0 %");
        private final Label alertas = new Label("0");
        private final Label saude = new Label("0");

        private final LineChart<String, Number> lineChart;
        private final BarChart<String, Number> barChart;
        private final GridPane heatMap = new GridPane();
        private final TextArea summary = new TextArea();
        private final ListView<String> recommendations = new ListView<>();
        private final TableView<SensorData> table = new TableView<>();

        private PeriodData lastData;

        private PeriodPanel(PeriodType period) {
            this.period = period;
            setPadding(new Insets(8));

            CategoryAxis lx = new CategoryAxis();
            NumberAxis ly = new NumberAxis();
            lineChart = new LineChart<>(lx, ly);
            lineChart.setTitle("Serie temporal - " + period.getLabel());
            lineChart.setAnimated(false);

            CategoryAxis bx = new CategoryAxis();
            NumberAxis by = new NumberAxis();
            barChart = new BarChart<>(bx, by);
            barChart.setTitle("Alertas por bloco");
            barChart.setAnimated(false);

            setTop(buildCards());
            setCenter(buildCenter());
            setBottom(buildBottom());
        }

        private Node buildCards() {
            GridPane cards = new GridPane();
            cards.setHgap(8);
            cards.setVgap(8);
            cards.setPadding(new Insets(0, 0, 8, 0));

            cards.add(kpiCard("Temp media", temp), 0, 0);
            cards.add(kpiCard("Umidade", umid), 1, 0);
            cards.add(kpiCard("Umid. solo", solo), 2, 0);
            cards.add(kpiCard("Tempo ideal", ideal), 3, 0);
            cards.add(kpiCard("Alertas", alertas), 4, 0);
            cards.add(kpiCard("Indice", saude), 5, 0);
            return cards;
        }

        private VBox kpiCard(String title, Label value) {
            Label name = new Label(title);
            name.getStyleClass().add("card-title");
            value.getStyleClass().add("card-value");

            VBox box = new VBox(4, name, value);
            box.setPadding(new Insets(10));
            box.getStyleClass().add("kpi-card");
            box.setPrefWidth(160);
            return box;
        }

        private Node buildCenter() {
            SplitPane split = new SplitPane();
            split.setDividerPositions(0.68);

            VBox left = new VBox(8, lineChart, barChart);
            VBox.setVgrow(lineChart, Priority.ALWAYS);
            VBox.setVgrow(barChart, Priority.ALWAYS);

            VBox right = new VBox(8, new Label("Heatmap de risco"), heatMap);
            right.setPadding(new Insets(2));

            split.getItems().addAll(left, right);
            return split;
        }

        private Node buildBottom() {
            SplitPane bottom = new SplitPane();
            bottom.setDividerPositions(0.55);
            bottom.setPrefHeight(260);

            configureTable();

            summary.setEditable(false);
            summary.setWrapText(true);
            summary.setPrefRowCount(6);

            VBox intelligence = new VBox(6,
                    new Label("Resumo automatico"),
                    summary,
                    new Label("Recomendacoes"),
                    recommendations
            );

            bottom.getItems().addAll(table, intelligence);
            return bottom;
        }

        private void configureTable() {
            table.setPlaceholder(new Label("Sem dados"));

            TableColumn<SensorData, Number> idCol = new TableColumn<>("ID");
            idCol.setCellValueFactory(value -> new javafx.beans.property.SimpleLongProperty(value.getValue().getId() == null ? 0 : value.getValue().getId()));

            TableColumn<SensorData, Number> tCol = new TableColumn<>("Temp");
            tCol.setCellValueFactory(value -> new javafx.beans.property.SimpleDoubleProperty(value.getValue().getTemperatura()));

            TableColumn<SensorData, Number> uCol = new TableColumn<>("Umidade");
            uCol.setCellValueFactory(value -> new javafx.beans.property.SimpleDoubleProperty(value.getValue().getUmidade()));

            TableColumn<SensorData, Number> sCol = new TableColumn<>("Solo");
            sCol.setCellValueFactory(value -> new javafx.beans.property.SimpleDoubleProperty(value.getValue().umidadeSoloOuZero()));

            TableColumn<SensorData, String> sigCol = new TableColumn<>("Significado");
            sigCol.setCellValueFactory(value -> new javafx.beans.property.SimpleStringProperty(value.getValue().getSignificado()));
            sigCol.setPrefWidth(300);

            table.getColumns().setAll(idCol, tCol, uCol, sCol, sigCol);
        }

        private void apply(PeriodData data) {
            this.lastData = data;

            temp.setText(String.format("%.1f C", data.getKpis().temperaturaMedia()));
            umid.setText(String.format("%.1f %%", data.getKpis().umidadeMedia()));
            solo.setText(String.format("%.1f %%", data.getKpis().umidadeSoloMedia()));
            ideal.setText(String.format("%.1f %%", data.getKpis().tempoFaixaIdealPct()));
            alertas.setText(String.valueOf(data.getKpis().alertasCriticos()));
            saude.setText(String.format("%.1f", data.getKpis().indiceSaude()));

            lineChart.getData().clear();
            XYChart.Series<String, Number> tempSeries = new XYChart.Series<>();
            tempSeries.setName("Temp");
            XYChart.Series<String, Number> umidSeries = new XYChart.Series<>();
            umidSeries.setName("Umid");
            XYChart.Series<String, Number> soloSeries = new XYChart.Series<>();
            soloSeries.setName("Solo");

            for (PeriodData.SeriesPoint point : data.getLinePoints()) {
                tempSeries.getData().add(new XYChart.Data<>(point.label(), point.temperatura()));
                umidSeries.getData().add(new XYChart.Data<>(point.label(), point.umidade()));
                soloSeries.getData().add(new XYChart.Data<>(point.label(), point.umidadeSolo()));
            }
            lineChart.getData().addAll(tempSeries, umidSeries, soloSeries);

            barChart.getData().clear();
            XYChart.Series<String, Number> alertSeries = new XYChart.Series<>();
            alertSeries.setName("Alertas");
            for (PeriodData.SeriesPoint point : data.getAlertPoints()) {
                alertSeries.getData().add(new XYChart.Data<>(point.label(), point.temperatura()));
            }
            barChart.getData().add(alertSeries);

            heatMap.getChildren().clear();
            heatMap.setHgap(3);
            heatMap.setVgap(3);
            for (PeriodData.HeatPoint point : data.getHeatPoints()) {
                Label cell = new Label(String.valueOf(point.value()));
                cell.setMinSize(34, 24);
                cell.setAlignment(Pos.CENTER);
                cell.setTextFill(Color.WHITE);

                String color = point.value() > 12 ? "#b42318" : point.value() > 4 ? "#eaaa08" : "#137547";
                cell.setStyle("-fx-background-color: " + color + "; -fx-background-radius: 4;");
                heatMap.add(cell, point.col(), point.row());
            }

            summary.setText(data.getSummary());
            recommendations.setItems(FXCollections.observableArrayList(data.getRecommendations()));

            table.setItems(FXCollections.observableArrayList(data.getSamples().stream().limit(200).toList()));
        }
    }
}
