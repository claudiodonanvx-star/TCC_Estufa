package br.com.estufa.desktop.ui;

import br.com.estufa.desktop.model.Alerta;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.control.*;
import javafx.scene.control.cell.PropertyValueFactory;
import javafx.scene.layout.*;
import javafx.scene.paint.Color;

import java.util.List;

public class AlertasTabView extends VBox {

    private final Label totalLabel = new Label("Total: 0");
    private final Label criticosLabel = new Label("Criticos: 0");
    private final Label atencaoLabel = new Label("Atencao: 0");

    private final TableView<Alerta> tabela = new TableView<>();
    private final ObservableList<Alerta> dados = FXCollections.observableArrayList();

    public AlertasTabView() {
        setSpacing(10);
        setPadding(new Insets(10));

        // --- Cards de contagem ---
        HBox cards = new HBox(12,
                buildBadge(totalLabel, "#475467"),
                buildBadge(criticosLabel, "#b42318"),
                buildBadge(atencaoLabel, "#b54708"));
        cards.setAlignment(Pos.CENTER_LEFT);

        // --- Tabela ---
        TableColumn<Alerta, Long> colId = new TableColumn<>("ID");
        colId.setCellValueFactory(new PropertyValueFactory<>("id"));
        colId.setPrefWidth(60);

        TableColumn<Alerta, String> colTipo = new TableColumn<>("Tipo");
        colTipo.setCellValueFactory(new PropertyValueFactory<>("tipo"));
        colTipo.setPrefWidth(110);

        TableColumn<Alerta, String> colSev = new TableColumn<>("Severidade");
        colSev.setCellValueFactory(new PropertyValueFactory<>("severidade"));
        colSev.setPrefWidth(100);
        colSev.setCellFactory(col -> new TableCell<>() {
            @Override
            protected void updateItem(String item, boolean empty) {
                super.updateItem(item, empty);
                if (empty || item == null) {
                    setText(null);
                    setStyle("");
                } else {
                    setText(item);
                    if ("CRITICO".equalsIgnoreCase(item)) {
                        setStyle("-fx-text-fill: #b42318; -fx-font-weight: bold;");
                    } else {
                        setStyle("-fx-text-fill: #b54708; -fx-font-weight: bold;");
                    }
                }
            }
        });

        TableColumn<Alerta, Float> colValor = new TableColumn<>("Valor");
        colValor.setCellValueFactory(new PropertyValueFactory<>("valor"));
        colValor.setPrefWidth(80);
        colValor.setCellFactory(col -> new TableCell<>() {
            @Override
            protected void updateItem(Float item, boolean empty) {
                super.updateItem(item, empty);
                setText(empty || item == null ? null : String.format("%.1f", item));
            }
        });

        TableColumn<Alerta, Float> colMin = new TableColumn<>("Min");
        colMin.setCellValueFactory(new PropertyValueFactory<>("limiteMin"));
        colMin.setPrefWidth(70);
        colMin.setCellFactory(col -> new TableCell<>() {
            @Override
            protected void updateItem(Float item, boolean empty) {
                super.updateItem(item, empty);
                setText(empty || item == null ? null : String.format("%.1f", item));
            }
        });

        TableColumn<Alerta, Float> colMax = new TableColumn<>("Max");
        colMax.setCellValueFactory(new PropertyValueFactory<>("limiteMax"));
        colMax.setPrefWidth(70);
        colMax.setCellFactory(col -> new TableCell<>() {
            @Override
            protected void updateItem(Float item, boolean empty) {
                super.updateItem(item, empty);
                setText(empty || item == null ? null : String.format("%.1f", item));
            }
        });

        TableColumn<Alerta, String> colMsg = new TableColumn<>("Mensagem");
        colMsg.setCellValueFactory(new PropertyValueFactory<>("mensagem"));
        colMsg.setPrefWidth(350);

        TableColumn<Alerta, String> colData = new TableColumn<>("Gerado em");
        colData.setCellValueFactory(new PropertyValueFactory<>("geradoEm"));
        colData.setPrefWidth(160);

        tabela.getColumns().addAll(colId, colTipo, colSev, colValor, colMin, colMax, colMsg, colData);
        tabela.setItems(dados);
        tabela.setColumnResizePolicy(TableView.CONSTRAINED_RESIZE_POLICY);
        VBox.setVgrow(tabela, Priority.ALWAYS);

        getChildren().addAll(cards, tabela);
    }

    public void applyData(List<Alerta> alertas) {
        dados.setAll(alertas);

        long criticos = alertas.stream().filter(Alerta::isCritico).count();
        long atencao = alertas.size() - criticos;

        totalLabel.setText("Total: " + alertas.size());
        criticosLabel.setText("Criticos: " + criticos);
        atencaoLabel.setText("Atencao: " + atencao);
    }

    public int getCriticosCount() {
        return (int) dados.stream().filter(Alerta::isCritico).count();
    }

    private VBox buildBadge(Label label, String cor) {
        label.setStyle("-fx-font-weight: bold; -fx-font-size: 14px; -fx-text-fill: " + cor + ";");
        VBox box = new VBox(4, label);
        box.setPadding(new Insets(8, 16, 8, 16));
        box.setStyle("-fx-background-color: #f9fafb; -fx-border-color: #e5e7eb; -fx-border-radius: 6; -fx-background-radius: 6;");
        return box;
    }
}
