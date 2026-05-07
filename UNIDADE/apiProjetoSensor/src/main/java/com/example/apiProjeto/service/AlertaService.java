package com.example.apiProjeto.service;

import com.example.apiProjeto.model.Alerta;
import com.example.apiProjeto.model.Cultivo;
import com.example.apiProjeto.model.SensorData;
import com.example.apiProjeto.repository.AlertaRepository;
import com.example.apiProjeto.repository.CultivoRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class AlertaService {

    @Autowired
    private AlertaRepository alertaRepository;

    @Autowired
    private CultivoRepository cultivoRepository;

    /**
     * Verifica se a leitura está fora dos limites do cultivo habilitado
     * e persiste alertas no banco para cada variável fora de faixa.
     */
    public void verificarEGerarAlertas(SensorData dados) {
        Cultivo cultivo = cultivoRepository.findFirstByHabilitadaTrueOrderByIdDesc();
        if (cultivo == null) return;

        List<Alerta> alertas = new ArrayList<>();

        // Temperatura
        float temp = dados.getTemperatura();
        if (temp < cultivo.getTemperaturaMinima() || temp > cultivo.getTemperaturaMaxima()) {
            String sev = (temp < cultivo.getTemperaturaMinima() - 3 || temp > cultivo.getTemperaturaMaxima() + 3)
                    ? "CRITICO" : "ATENCAO";
            String dir = temp < cultivo.getTemperaturaMinima() ? "abaixo do minimo" : "acima do maximo";
            alertas.add(new Alerta("TEMPERATURA", sev, temp,
                    cultivo.getTemperaturaMinima(), cultivo.getTemperaturaMaxima(),
                    String.format("Temperatura %.1fC %s (faixa: %.1f-%.1fC)", temp, dir,
                            cultivo.getTemperaturaMinima(), cultivo.getTemperaturaMaxima())));
        }

        // Umidade do ar
        float umidade = dados.getUmidade();
        if (umidade < cultivo.getUmidadeMinima() || umidade > cultivo.getUmidadeMaxima()) {
            String sev = (umidade < cultivo.getUmidadeMinima() - 10 || umidade > cultivo.getUmidadeMaxima() + 10)
                    ? "CRITICO" : "ATENCAO";
            String dir = umidade < cultivo.getUmidadeMinima() ? "abaixo do minimo" : "acima do maximo";
            alertas.add(new Alerta("UMIDADE", sev, umidade,
                    cultivo.getUmidadeMinima(), cultivo.getUmidadeMaxima(),
                    String.format("Umidade %.1f%% %s (faixa: %.1f-%.1f%%)", umidade, dir,
                            cultivo.getUmidadeMinima(), cultivo.getUmidadeMaxima())));
        }

        // Umidade do solo (se disponível)
        if (dados.getUmidadeSolo() != null) {
            float solo = dados.getUmidadeSolo();
            if (solo < cultivo.getUmidadeSoloMinima() || solo > cultivo.getUmidadeSoloMaxima()) {
                String sev = (solo < cultivo.getUmidadeSoloMinima() - 10 || solo > cultivo.getUmidadeSoloMaxima() + 10)
                        ? "CRITICO" : "ATENCAO";
                String dir = solo < cultivo.getUmidadeSoloMinima() ? "abaixo do minimo" : "acima do maximo";
                alertas.add(new Alerta("SOLO", sev, solo,
                        cultivo.getUmidadeSoloMinima(), cultivo.getUmidadeSoloMaxima(),
                        String.format("Umidade solo %.1f%% %s (faixa: %.1f-%.1f%%)", solo, dir,
                                cultivo.getUmidadeSoloMinima(), cultivo.getUmidadeSoloMaxima())));
            }
        }

        if (!alertas.isEmpty()) {
            alertaRepository.saveAll(alertas);
        }
    }
}
