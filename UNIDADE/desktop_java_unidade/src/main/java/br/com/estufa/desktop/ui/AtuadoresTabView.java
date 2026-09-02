package br.com.estufa.desktop.ui;

import java.util.function.BiConsumer;
import java.util.function.Consumer;

import com.fasterxml.jackson.databind.JsonNode;

import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.control.Button;
import javafx.scene.control.CheckBox;
import javafx.scene.control.Label;
import javafx.scene.layout.HBox;
import javafx.scene.layout.Priority;
import javafx.scene.layout.VBox;
import javafx.scene.paint.Color;

public class AtuadoresTabView extends VBox {

    private static final int DURACAO_MANUAL_SEGUNDOS = 55;
    // Aquecedor fica ligado por menos tempo que os demais reles por seguranca.
    private static final int DURACAO_AQUECEDOR_SEGUNDOS = 35;
    // Bomba fica ligada por menos tempo para nao drenar a agua rapido demais.
    private static final int DURACAO_BOMBA_SEGUNDOS = 15;

    private final CheckBox modoAutomaticoCheck = new CheckBox("Modo automatico");
    private final ReleCard bombaCard = new ReleCard("Bomba");
    private final ReleCard coolerCard = new ReleCard("Cooler");
    private final ReleCard temperaturaCard = new ReleCard("Aquecedor");

    public AtuadoresTabView(Consumer<Boolean> onToggleModoAutomatico, BiConsumer<String, Integer> onAcionar) {
        setSpacing(14);
        setPadding(new Insets(12));

        modoAutomaticoCheck.setOnAction(e -> onToggleModoAutomatico.accept(modoAutomaticoCheck.isSelected()));

        bombaCard.acionarButton.setOnAction(e -> onAcionar.accept("bomba", DURACAO_BOMBA_SEGUNDOS));
        coolerCard.acionarButton.setOnAction(e -> onAcionar.accept("cooler", DURACAO_MANUAL_SEGUNDOS));
        temperaturaCard.acionarButton.setOnAction(e -> onAcionar.accept("temperatura", DURACAO_AQUECEDOR_SEGUNDOS));

        HBox cards = new HBox(12, bombaCard, coolerCard, temperaturaCard);
        cards.setAlignment(Pos.CENTER_LEFT);
        HBox.setHgrow(cards, Priority.ALWAYS);

        getChildren().addAll(modoAutomaticoCheck, cards);
    }

    public void applyEstado(JsonNode estado) {
        if (estado == null) {
            return;
        }
        modoAutomaticoCheck.setSelected(estado.path("modoAutomatico").asBoolean(false));
        bombaCard.setLigado(estado.path("bombaLigada").asBoolean(false));
        coolerCard.setLigado(estado.path("coolerLigado").asBoolean(false));
        temperaturaCard.setLigado(estado.path("temperaturaLigada").asBoolean(false));
    }

    private static final class ReleCard extends VBox {
        private final Label estadoLabel = new Label("Desligado");
        private final Button acionarButton = new Button("Acionar");

        private ReleCard(String titulo) {
            setSpacing(8);
            setPadding(new Insets(10));
            setAlignment(Pos.CENTER);
            setStyle("-fx-background-color: #f2f4f7; -fx-background-radius: 8;");

            Label tituloLabel = new Label(titulo);
            tituloLabel.setStyle("-fx-font-weight: bold;");

            getChildren().addAll(tituloLabel, estadoLabel, acionarButton);
        }

        private void setLigado(boolean ligado) {
            estadoLabel.setText(ligado ? "Ligado" : "Desligado");
            estadoLabel.setTextFill(ligado ? Color.web("#12793f") : Color.web("#667085"));
        }
    }
}
