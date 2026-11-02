package com.example.apiProjeto.controller;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.LocalDate;
import java.util.List;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.example.apiProjeto.repository.RelatorioDiarioRepository;
import com.example.apiProjeto.service.ConsolidacaoService;

@ExtendWith(MockitoExtension.class)
class RelatoriosControllerTest {

    @Mock
    private RelatorioDiarioRepository relatorioRepository;

    @Mock
    private ConsolidacaoService consolidacaoService;

    @InjectMocks
    private RelatoriosController controller;

    @Test
    void getSemanal_incluiDiaAtual() {
        LocalDate hoje = LocalDate.now();
        when(relatorioRepository.findByDataRefBetweenOrderByDataRef(
                hoje.minusDays(6), hoje)).thenReturn(List.of());

        controller.getSemanal();

        verify(relatorioRepository).findByDataRefBetweenOrderByDataRef(
                hoje.minusDays(6), hoje);
    }

    @Test
    void getMensal_incluiDiaAtual() {
        LocalDate hoje = LocalDate.now();
        when(relatorioRepository.findByDataRefBetweenOrderByDataRef(
                hoje.minusDays(29), hoje)).thenReturn(List.of());

        controller.getMensal();

        verify(relatorioRepository).findByDataRefBetweenOrderByDataRef(
                hoje.minusDays(29), hoje);
    }

    @Test
    void consolidarHoje_consolidaDataDoServidor() {
        LocalDate hoje = LocalDate.now();
        when(consolidacaoService.consolidarDia(hoje)).thenReturn("Consolidado");

        assertEquals(200, controller.consolidarHoje().getStatusCode().value());
        verify(consolidacaoService).consolidarDia(hoje);
    }
}
