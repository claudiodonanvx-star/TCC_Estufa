package br.com.estufa.desktop;

import br.com.estufa.desktop.model.Alerta;
import br.com.estufa.desktop.model.Cultivo;
import br.com.estufa.desktop.model.PeriodData;
import br.com.estufa.desktop.model.PeriodType;
import br.com.estufa.desktop.model.RelatorioDiario;
import br.com.estufa.desktop.model.SensorData;
import br.com.estufa.desktop.model.UserRole;
import br.com.estufa.desktop.model.UserSession;
import br.com.estufa.desktop.service.AnalyticsService;
import br.com.estufa.desktop.service.ApiService;
import br.com.estufa.desktop.service.ExportService;
import br.com.estufa.desktop.ui.MainDashboardView;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.node.JsonNodeFactory;
import javafx.application.Application;
import javafx.application.Platform;
import javafx.concurrent.Task;
import javafx.geometry.Insets;
import javafx.scene.Scene;
import javafx.scene.control.*;
import javafx.scene.layout.GridPane;
import javafx.stage.FileChooser;
import javafx.stage.Stage;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

public class DesktopUnidadeApp extends Application {

    private final ApiService apiService = new ApiService();
    private final AnalyticsService analyticsService = new AnalyticsService();
    private final ExportService exportService = new ExportService();

    private MainDashboardView dashboardView;
    private UserSession currentSession;

    @Override
    public void start(Stage stage) {
        currentSession = authenticateUser();
        if (currentSession == null) {
            Platform.exit();
            return;
        }

        dashboardView = new MainDashboardView(
                currentSession.username(),
                currentSession.role(),
                this::refreshData,
                (period, format) -> export(stage, period, format),
                data -> consolidar(data),
                this::alterarModoAutomatico,
                this::acionarAtuador
        );

        Scene scene = new Scene(dashboardView, 1520, 900);
        scene.getStylesheets().add(getClass().getResource("/styles.css").toExternalForm());

        stage.setTitle("Estufa Smart Desktop - UNIDADE");
        stage.setScene(scene);
        stage.show();

        refreshData();
    }

    private UserSession authenticateUser() {
        while (true) {
            Dialog<LoginInput> dialog = new Dialog<>();
            dialog.setTitle("Acesso ao Desktop");
            dialog.setHeaderText("Entre com CPF e senha (mesmo usuario do mobile)");

            ButtonType loginButtonType = new ButtonType("Entrar", ButtonBar.ButtonData.OK_DONE);
            dialog.getDialogPane().getButtonTypes().addAll(loginButtonType, ButtonType.CANCEL);

            TextField usernameField = new TextField();
            usernameField.setPromptText("CPF (somente numeros)");
            PasswordField passwordField = new PasswordField();
            passwordField.setPromptText("Senha");

            GridPane grid = new GridPane();
            grid.setHgap(10);
            grid.setVgap(10);
            grid.setPadding(new Insets(10, 10, 10, 10));
            grid.add(new Label("CPF:"), 0, 0);
            grid.add(usernameField, 1, 0);
            grid.add(new Label("Senha:"), 0, 1);
            grid.add(passwordField, 1, 1);

            dialog.getDialogPane().setContent(grid);

            dialog.setResultConverter(button -> {
                if (button == loginButtonType) {
                    return new LoginInput(usernameField.getText(), passwordField.getText());
                }
                return null;
            });

            Optional<LoginInput> result = dialog.showAndWait();
            if (result.isEmpty()) {
                return null;
            }

            LoginInput input = result.get();
            String username = input.username() == null ? "" : input.username().trim();
            String password = input.password() == null ? "" : input.password().trim();

            if (username.isBlank() || password.isBlank()) {
                Alert alert = new Alert(Alert.AlertType.WARNING);
                alert.setHeaderText("Campos obrigatorios");
                alert.setContentText("Informe CPF e senha.");
                alert.showAndWait();
                continue;
            }

            try {
                ApiService.LoginResult loginResult = apiService.login(username, password);
                UserRole role = loginResult.administrador() ? UserRole.ADMIN : UserRole.CLIENTE;
                return new UserSession(loginResult.cpf(), role);
            } catch (IllegalStateException e) {
                Alert alert = new Alert(Alert.AlertType.WARNING);
                alert.setHeaderText("Falha no login");
                alert.setContentText(e.getMessage());
                alert.showAndWait();
            } catch (Exception e) {
                Alert alert = new Alert(Alert.AlertType.ERROR);
                alert.setHeaderText("Erro ao conectar na API");
                alert.setContentText(e.getMessage());
                alert.showAndWait();
            }
        }
    }

    private void refreshData() {
        String historicoPeriodo = dashboardView != null
                ? dashboardView.getHistoricoTabView().getSelectedPeriodo()
                : "mensal";

        Task<RefreshResult> task = new Task<>() {
            @Override
            protected RefreshResult call() throws Exception {
                boolean apiOnline = apiService.isApiOnline();
                List<SensorData> all = apiService.fetchSensorData();
                Cultivo cultivo = apiService.fetchCultivoHabilitado();

                Map<PeriodType, PeriodData> map = new EnumMap<>(PeriodType.class);
                for (PeriodType p : PeriodType.values()) {
                    map.put(p, analyticsService.buildPeriodData(all, cultivo, p));
                }

                List<RelatorioDiario> historico = fetchHistorico(historicoPeriodo);

                List<Alerta> alertas;
                try {
                    alertas = apiService.fetchAlertas();
                } catch (Exception e) {
                    alertas = List.of();
                }

                JsonNode atuadores;
                try {
                    atuadores = apiService.fetchAtuadoresEstado();
                } catch (Exception e) {
                    atuadores = JsonNodeFactory.instance.objectNode();
                }

                return new RefreshResult(apiOnline, cultivo, all.size(), map, all, historico, alertas, atuadores);
            }
        };

        task.setOnSucceeded(event -> {
            RefreshResult result = task.getValue();
            dashboardView.applyData(result.byPeriod(), result.cultivo(), result.apiOnline(), result.samples(), result.allSamples());
            dashboardView.applyHistorico(result.historico());
            dashboardView.applyAlertas(result.alertas());
            dashboardView.applyAtuadores(result.atuadores());
        });

        task.setOnFailed(event -> {
            Throwable ex = task.getException();
            dashboardView.showError(ex == null ? "Erro desconhecido" : ex.getMessage());
        });

        Thread thread = new Thread(task, "dashboard-refresh");
        thread.setDaemon(true);
        thread.start();
    }

    private List<RelatorioDiario> fetchHistorico(String periodo) {
        try {
            return switch (periodo) {
                case "semanal" -> apiService.fetchRelatoriosSemanal();
                case "anual" -> apiService.fetchRelatoriosAnual();
                default -> apiService.fetchRelatoriosMensal();
            };
        } catch (Exception e) {
            return List.of();
        }
    }

    private void consolidar(String data) {
        Task<String> task = new Task<>() {
            @Override
            protected String call() throws Exception {
                return apiService.triggerConsolidar(data);
            }
        };

        task.setOnSucceeded(event -> {
            dashboardView.showConsolidarResult(task.getValue());
            refreshData();
        });

        task.setOnFailed(event -> {
            Throwable ex = task.getException();
            dashboardView.showError("Erro ao consolidar: " + (ex == null ? "Desconhecido" : ex.getMessage()));
        });

        Thread thread = new Thread(task, "consolidar-job");
        thread.setDaemon(true);
        thread.start();
    }

    private void export(Stage stage, PeriodType period, String format) {
        if (period == null) {
            dashboardView.showError("Selecione um periodo para exportar.");
            return;
        }

        FileChooser chooser = new FileChooser();
        chooser.setTitle("Exportar relatorio " + period.getLabel());

        String extension = format.equalsIgnoreCase("pdf") ? "*.pdf" : "*.csv";
        chooser.getExtensionFilters().add(new FileChooser.ExtensionFilter(format.toUpperCase() + " files", extension));

        String baseName = "relatorio_" + period.getLabel().toLowerCase();
        chooser.setInitialFileName(baseName + (format.equalsIgnoreCase("pdf") ? ".pdf" : ".csv"));

        File selected = chooser.showSaveDialog(stage);
        if (selected == null) {
            return;
        }

        Path path = selected.toPath();

        if (format.equalsIgnoreCase("csv")) {
            exportCsvConsolidado(period, path);
            return;
        }

        PeriodData data = dashboardView.getPeriodForExport(period);
        if (data == null) {
            dashboardView.showError("Sem dados para exportar neste periodo.");
            return;
        }

        try {
            exportService.exportPdf(path, data);
        } catch (IOException e) {
            dashboardView.showError("Falha ao exportar PDF: " + e.getMessage());
        }
    }

    private void exportCsvConsolidado(PeriodType period, Path path) {
        String tipo = switch (period) {
            case DIARIO -> "semanal";
            case SEMANAL -> "semanal";
            case MENSAL -> "mensal";
        };

        Task<String> task = new Task<>() {
            @Override
            protected String call() throws Exception {
                return apiService.fetchRelatoriosCsv(tipo);
            }
        };

        task.setOnSucceeded(event -> {
            try {
                Files.writeString(path, task.getValue(), StandardCharsets.UTF_8);
            } catch (IOException e) {
                dashboardView.showError("Falha ao salvar CSV: " + e.getMessage());
            }
        });

        task.setOnFailed(event -> {
            PeriodData data = dashboardView.getPeriodForExport(period);
            if (data != null) {
                try {
                    exportService.exportCsv(path, data);
                } catch (IOException e) {
                    dashboardView.showError("Falha ao exportar CSV: " + e.getMessage());
                }
            } else {
                dashboardView.showError("Sem dados para exportar.");
            }
        });

        Thread thread = new Thread(task, "export-csv");
        thread.setDaemon(true);
        thread.start();
    }

    public static void main(String[] args) {
        launch(args);
    }

    private record LoginInput(String username, String password) {}

    private record RefreshResult(boolean apiOnline, Cultivo cultivo, int samples,
                                  Map<PeriodType, PeriodData> byPeriod, List<SensorData> allSamples,
                                  List<RelatorioDiario> historico, List<Alerta> alertas, JsonNode atuadores) {}

    private void alterarModoAutomatico(boolean ativo) {
        Task<JsonNode> task = new Task<>() {
            @Override
            protected JsonNode call() throws Exception {
                return apiService.definirModoAutomaticoAtuadores(ativo);
            }
        };

        task.setOnSucceeded(event -> dashboardView.applyAtuadores(task.getValue()));
        task.setOnFailed(event -> {
            Throwable ex = task.getException();
            dashboardView.showError("Erro ao alterar modo dos reles: " + (ex == null ? "Desconhecido" : ex.getMessage()));
        });

        Thread thread = new Thread(task, "atuador-modo");
        thread.setDaemon(true);
        thread.start();
    }

    private void acionarAtuador(String atuador, int duracaoSegundos) {
        Task<JsonNode> task = new Task<>() {
            @Override
            protected JsonNode call() throws Exception {
                return apiService.acionarAtuador(atuador, duracaoSegundos);
            }
        };

        task.setOnSucceeded(event -> dashboardView.applyAtuadores(task.getValue()));
        task.setOnFailed(event -> {
            Throwable ex = task.getException();
            dashboardView.showError("Erro ao acionar " + atuador + ": " + (ex == null ? "Desconhecido" : ex.getMessage()));
        });

        Thread thread = new Thread(task, "atuador-acionar");
        thread.setDaemon(true);
        thread.start();
    }
}
