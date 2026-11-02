package com.example.apiProjeto.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import com.example.apiProjeto.model.Cultivo;
import com.example.apiProjeto.repository.CultivoRepository;
import com.fasterxml.jackson.databind.ObjectMapper;

class ConsultaBotanicaCadastroTest {

    private CultivoRepository cultivoRepository;
    private ConsultaBotanicaService service;

    @BeforeEach
    void setUp() {
        cultivoRepository = mock(CultivoRepository.class);
        when(cultivoRepository.findAll()).thenReturn(List.of());
        service = new ConsultaBotanicaService(
                new ObjectMapper(),
                "",
                "",
                "",
                "gemini",
                null,
                null,
                cultivoRepository,
                null,
                null,
                null,
                null);
    }

    @Test
    void prepararCadastro_comFaixasInformadasPeloUsuario_criaSomenteUmaPropostaDesabilitada() throws Exception {
        Map<String, Object> resultado = service.prepararCadastroCultivo(
                argumentos("usuario"),
                "Cadastre abacaxi: temperatura 18 e 30, umidade 60 e 80, solo 40 e 70.",
                List.of());

        assertTrue(resultado.containsKey("cadastroPendente"));
        @SuppressWarnings("unchecked")
        Map<String, Object> proposta = (Map<String, Object>) resultado.get("cadastroPendente");
        @SuppressWarnings("unchecked")
        Map<String, Object> cultivo = (Map<String, Object>) proposta.get("cultivo");
        assertEquals(false, cultivo.get("habilitada"));
        assertEquals("valores informados por você", proposta.get("origem"));
        verify(cultivoRepository, never()).save(org.mockito.ArgumentMatchers.any(Cultivo.class));
    }

    @Test
    void prepararCadastro_semValoresConfirmados_naoGeraProposta() throws Exception {
        Map<String, Object> resultado = service.prepararCadastroCultivo(
                argumentos("externa"),
                "Cadastre abacaxi.",
                List.of(Map.of(
                        "termoBusca", "abacaxi",
                        "resumo", "O abacaxi é uma planta tropical cultivada em várias regiões.",
                        "titulo", "Abacaxi",
                        "url", "https://pt.wikipedia.org/wiki/Abacaxi")));

        assertTrue(resultado.containsKey("erro"));
        assertFalse(resultado.containsKey("cadastroPendente"));
        verify(cultivoRepository, never()).save(org.mockito.ArgumentMatchers.any(Cultivo.class));
    }

    @Test
    void prepararCadastro_permiteFaixasPreliminaresComRiscoConfirmadoPeloUsuario() throws Exception {
        Map<String, Object> resultado = service.prepararCadastroCultivo(
                argumentosEstimados(),
                "Cadastre lírio-aranha.",
                List.of());

        assertTrue(resultado.containsKey("cadastroPendente"));
        @SuppressWarnings("unchecked")
        Map<String, Object> proposta = (Map<String, Object>) resultado.get("cadastroPendente");
        assertEquals(true, proposta.get("estimativaNaoVerificada"));
        assertTrue(proposta.get("observacao").toString().contains("assume o risco"));
        @SuppressWarnings("unchecked")
        Map<String, Object> cultivo = (Map<String, Object>) proposta.get("cultivo");
        assertEquals(false, cultivo.get("habilitada"));
        verify(cultivoRepository, never()).save(org.mockito.ArgumentMatchers.any(Cultivo.class));
    }

    @Test
    void prepararCadastro_aceitaEstimativaDeSoloParaCultivoDiferenteDePepino() throws Exception {
        Map<String, String> fonte = Map.of(
                "termoBusca", "lírio-da-paz",
                "resumo", "Temperatura mínima 18 e máxima 30 °C; umidade relativa do ar mínima 70 e máxima 90%.",
                "titulo", "Cuidados de cultivo do lírio-da-paz",
                "url", "https://example.org/lirio-da-paz");

        Map<String, Object> resultado = service.prepararCadastroCultivo(
                argumentosEstimativaSolo(),
                "Cadastre lírio-da-paz.",
                List.of(fonte));

        assertTrue(resultado.containsKey("cadastroPendente"));
        @SuppressWarnings("unchecked")
        Map<String, Object> proposta = (Map<String, Object>) resultado.get("cadastroPendente");
        @SuppressWarnings("unchecked")
        Map<String, Object> cultivo = (Map<String, Object>) proposta.get("cultivo");
        assertEquals(60.0, cultivo.get("umidadeSoloMinima"));
        assertEquals(80.0, cultivo.get("umidadeSoloMaxima"));
        assertEquals(true, proposta.get("umidadeSoloEstimada"));
        assertTrue(proposta.get("observacao").toString().contains("genérica"));
        assertTrue(proposta.get("observacao").toString().contains("não uma recomendação específica"));
        verify(cultivoRepository, never()).save(org.mockito.ArgumentMatchers.any(Cultivo.class));
    }

    @Test
    void prepararCadastro_comValoresPresentesEmFonteDoCultivo_criaPropostaComCitacao() throws Exception {
        Map<String, String> fonte = Map.of(
                "termoBusca", "abacaxi cultivo",
                "resumo", "Faixas observadas: 18 30 60 80 40 70.",
                "titulo", "Cultivo de abacaxi",
                "url", "https://pt.wikipedia.org/wiki/Abacaxi");

        Map<String, Object> resultado = service.prepararCadastroCultivo(
                argumentos("externa"),
                "Cadastre abacaxi.",
                List.of(fonte));

        assertTrue(resultado.containsKey("cadastroPendente"));
        @SuppressWarnings("unchecked")
        Map<String, Object> proposta = (Map<String, Object>) resultado.get("cadastroPendente");
        assertEquals(List.of(fonte), proposta.get("fontes"));
        verify(cultivoRepository, never()).save(org.mockito.ArgumentMatchers.any(Cultivo.class));
    }

    private com.fasterxml.jackson.databind.JsonNode argumentos(String origem) throws Exception {
        return new ObjectMapper().readTree("""
                {
                  "nome": "Abacaxi",
                  "tipo": "Fruta",
                  "temperaturaMinima": 18,
                  "temperaturaMaxima": 30,
                  "umidadeMinima": 60,
                  "umidadeMaxima": 80,
                  "umidadeSoloMinima": 40,
                  "umidadeSoloMaxima": 70,
                  "origem": "%s"
                }
                """.formatted(origem));
    }

    private com.fasterxml.jackson.databind.JsonNode argumentosEstimativaSolo() throws Exception {
        return new ObjectMapper().readTree("""
                {
                  "nome": "Lírio-da-paz",
                  "tipo": "Planta ornamental",
                  "temperaturaMinima": 18,
                  "temperaturaMaxima": 30,
                  "umidadeMinima": 70,
                  "umidadeMaxima": 90,
                  "umidadeSoloMinima": 60,
                  "umidadeSoloMaxima": 80,
                  "origem": "estimada",
                  "umidadeSoloEstimada": true
                }
                """);
    }

    private com.fasterxml.jackson.databind.JsonNode argumentosEstimados() throws Exception {
        return new ObjectMapper().readTree("""
                {
                  "nome": "Lírio-aranha",
                  "tipo": "Planta ornamental",
                  "temperaturaMinima": 15,
                  "temperaturaMaxima": 24,
                  "umidadeMinima": 40,
                  "umidadeMaxima": 60,
                  "umidadeSoloMinima": 60,
                  "umidadeSoloMaxima": 80,
                  "origem": "estimada",
                  "umidadeSoloEstimada": true,
                  "estimativaNaoVerificada": true
                }
                """);
    }
}
