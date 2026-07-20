package com.winwintravel.dataapi.transform;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class TransformControllerTest {

    private MockMvc mockMvc;

    private static final String TRANSFORM_PATH = "/api/transform";
    private static final String INTERNAL_TOKEN_HEADER = "X-Internal-Token";
    private static final String INTERNAL_TOKEN = "test-internal-token";
    private static final String VALID_TEXT = "hello";
    private static final String UPPERCASE_TEXT = "HELLO";

    @BeforeEach
    void setUp() {
        TransformController controller = new TransformController();
        ReflectionTestUtils.setField(controller, "internalToken", INTERNAL_TOKEN);
        mockMvc = MockMvcBuilders.standaloneSetup(controller).build();
    }

    @Test
    void transform_shouldReturnUppercaseResult_forValidInternalToken() throws Exception {
        mockMvc.perform(post(TRANSFORM_PATH)
                .contentType("application/json")
                .header(INTERNAL_TOKEN_HEADER, INTERNAL_TOKEN)
                .content("""
                        {
                          "text": "%s"
                        }
                        """.formatted(VALID_TEXT)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result").value(UPPERCASE_TEXT));    }

    @Test
    void transform_shouldReturnEmptyResult_whenTextIsNull() throws Exception {
        mockMvc.perform(post(TRANSFORM_PATH)
                .contentType("application/json")
                .header(INTERNAL_TOKEN_HEADER, INTERNAL_TOKEN)
                .content("""
                                {
                                  "text": null
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result").value(""));
    }

    @Test
    void transform_shouldReturnForbidden_whenInternalTokenIsMissing() throws Exception {
        mockMvc.perform(post(TRANSFORM_PATH)
                .contentType("application/json")
                .content("""
                        {
                          "text": "%s"
                        }
                        """.formatted(VALID_TEXT)))
                .andExpect(status().isForbidden());
    }

    @Test
    void transform_shouldReturnForbidden_whenInternalTokenIsInvalid() throws Exception {
        mockMvc.perform(post(TRANSFORM_PATH)
                .contentType("application/json")
                .header(INTERNAL_TOKEN_HEADER, "wrong-token")
                .content("""
                        {
                          "text": "%s"
                        }
                        """.formatted(VALID_TEXT)))
                .andExpect(status().isForbidden());
    }
}
