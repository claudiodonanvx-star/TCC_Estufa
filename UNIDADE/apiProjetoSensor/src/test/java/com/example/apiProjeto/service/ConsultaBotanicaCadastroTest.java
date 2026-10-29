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
}
