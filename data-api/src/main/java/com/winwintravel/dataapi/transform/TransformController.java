    package com.winwintravel.dataapi.transform;

    import org.springframework.beans.factory.annotation.Value;
    import org.springframework.http.HttpStatus;
    import org.springframework.web.bind.annotation.PostMapping;
    import org.springframework.web.bind.annotation.RequestBody;
    import org.springframework.web.bind.annotation.RequestHeader;
    import org.springframework.web.bind.annotation.RequestMapping;
    import org.springframework.web.bind.annotation.RestController;
    import org.springframework.web.server.ResponseStatusException;

    @RestController
    @RequestMapping("/api")
    public class TransformController {

        private static final String INTERNAL_TOKEN_HEADER = "X-Internal-Token";

        @Value("${internal.token}")
        private String internalToken;

        @PostMapping("/transform")
        public TransformResponse transform(
                @RequestHeader(value = INTERNAL_TOKEN_HEADER, required = false) String headerToken,
                @RequestBody TransformRequest request
        ) {
            if (headerToken == null || !headerToken.equals(internalToken)) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Invalid internal token");
            }

            String input = request == null || request.text() == null ? "" : request.text();
            String result = new StringBuilder(input).reverse().toString();

            return new TransformResponse(result);
        }
    }
        