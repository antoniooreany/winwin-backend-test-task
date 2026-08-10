# API Contract Specification

Version: **v0.3.7**  
Status: **Stable**

This document is the authoritative API contract for the WinWin Backend Test Task.  
All endpoint implementations MUST conform to this specification.

Cross-references:
- [System spec](./system.md) — overall architecture
- [Invariants](./invariants.md) — behavioral constraints
- [Verification guide](../docs/verification.md) — how to verify conformance

---

## Base URLs

| Service | Base URL (local) |
|---------|-----------------|
| auth-api | `http://localhost:8080` |
| data-api | `http://localhost:8081` |

---

## auth-api Endpoints

### Health check

```
GET /health
```

**Response** `200 OK`
```json
{"status": "ok", "service": "auth-api"}
```

No authentication required.

---

### Register

```
POST /api/auth/register
Content-Type: application/json
```

**Request body**
```json
{
  "email": "string",
  "password": "string"
}
```

**Constraints:**
- `email`: valid email format, must be unique
- `password`: must meet minimum complexity (at least 8 chars, 1 uppercase, 1 digit, 1 special char)

**Responses**

| Status | Meaning |
|--------|---------|
| 201 Created | User registered successfully |
| 409 Conflict | Email already exists |
| 400 Bad Request | Validation failure |

---

### Login

```
POST /api/auth/login
Content-Type: application/json
```

**Request body**
```json
{
  "email": "string",
  "password": "string"
}
```

**Responses**

| Status | Meaning | Body |
|--------|---------|------|
| 200 OK | Authenticated | `{"token": "<JWT>"}` |
| 401 Unauthorized | Invalid credentials | error body |

---

### Protected processing

```
POST /api/process
Authorization: Bearer <JWT>
Content-Type: application/json
```

**Request body**
```json
{
  "text": "string"
}
```

**Behavior:**
1. Validates JWT
2. Forwards `text` to `data-api POST /api/transform`
3. Persists a row in `processinglog`
4. Returns transformed result

**Responses**

| Status | Meaning | Body |
|--------|---------|------|
| 200 OK | Success | `{"result": "string"}` |
| 403 Forbidden | No JWT / invalid JWT | error body |
| 401 Unauthorized | Token expired | error body |

---

### Swagger UI

```
GET /swagger-ui.html
```

Interactive API documentation. No authentication required.

---

## data-api Endpoints

### Health check

```
GET /health
```

**Response** `200 OK`
```json
{"status": "ok", "service": "data-api"}
```

No authentication required.

---

### Transform (internal only)

```
POST /api/transform
X-Internal-Token: <shared secret>
Content-Type: application/json
```

**Request body**
```json
{
  "text": "string"
}
```

**Behavior:** Returns the input text reversed.

**Responses**

| Status | Meaning | Body |
|--------|---------|------|
| 200 OK | Success | `{"result": "string"}` |
| 403 Forbidden | Missing or wrong X-Internal-Token | error body |

> **INVARIANT:** Direct external access to `/api/transform` without a valid `X-Internal-Token` MUST always be rejected with 403. See [invariants.md](./invariants.md).

---

## Error Response Format

All error responses follow a consistent structure:

```json
{
  "error": "string",
  "message": "string"
}
```

---

## Transformation Example

| Input | Output |
|-------|--------|
| `hello` | `olleh` |
| `WinWin` | `niWniW` |
