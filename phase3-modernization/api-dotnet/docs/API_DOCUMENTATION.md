# API Documentation

## Overview

The Job Site API provides RESTful endpoints for managing job postings, companies, job seekers, and resumes.

## Base URL

```
https://api.jobsite.com/api
```

## Authentication

All requests require a valid JWT token in the Authorization header:

```
Authorization: Bearer <your_jwt_token>
```

## Endpoints

### Companies

#### Create Company

```
POST /api/companies
Content-Type: application/json

{
  "companyName": "Tech Corp",
  "briefProfile": "Leading tech company",
  "address1": "123 Main St",
  "city": "San Francisco",
  "stateId": 1,
  "countryId": 1,
  "postalCode": "94102",
  "phone": "+1-555-0123",
  "email": "contact@techcorp.com",
  "websiteUrl": "https://techcorp.com"
}

Response (201 Created):
{
  "id": 1,
  "userId": "user-123",
  "companyName": "Tech Corp",
  ...
  "createdAt": "2026-01-20T10:30:00Z"
}
```

#### Get Company

```
GET /api/companies/{id}

Response (200 OK):
{
  "id": 1,
  "companyName": "Tech Corp",
  ...
}
```

#### Update Company

```
PUT /api/companies/{id}
Content-Type: application/json

{
  "companyName": "Tech Corp Updated",
  ...
}

Response (200 OK):
```

#### Delete Company

```
DELETE /api/companies/{id}

Response (204 No Content):
```

### Job Postings

#### Create Job Posting

```
POST /api/jobpostings
Content-Type: application/json

{
  "companyId": 1,
  "title": "Senior Software Engineer",
  "description": "Looking for experienced developer...",
  "department": "Engineering",
  "jobCode": "SE-001",
  "contactPerson": "John Doe",
  "city": "San Francisco",
  "stateId": 1,
  "countryId": 1,
  "educationLevelId": 3,
  "jobTypeId": 1,
  "minimumSalary": 100000,
  "maximumSalary": 150000
}

Response (201 Created):
{
  "id": 1,
  "companyId": 1,
  "title": "Senior Software Engineer",
  ...
  "createdAt": "2026-01-20T10:30:00Z"
}
```

#### List Job Postings

```
GET /api/jobpostings?page=1&pageSize=10&searchTerm=engineer

Response (200 OK):
{
  "items": [...],
  "totalCount": 42,
  "pageNumber": 1,
  "pageSize": 10
}
```

#### Get Job Posting

```
GET /api/jobpostings/{id}

Response (200 OK):
{
  "id": 1,
  "title": "Senior Software Engineer",
  ...
}
```

## Error Responses

### 400 Bad Request

```json
{
  "type": "https://tools.ietf.org/html/rfc9110#section-15.5.1",
  "title": "Bad Request",
  "status": 400,
  "detail": "One or more validation errors occurred.",
  "errors": {
    "CompanyName": ["Company name is required"]
  }
}
```

### 401 Unauthorized

```json
{
  "type": "https://tools.ietf.org/html/rfc9110#section-15.1.2",
  "title": "Unauthorized",
  "status": 401,
  "detail": "Invalid or missing authentication token"
}
```

### 404 Not Found

```json
{
  "type": "https://tools.ietf.org/html/rfc9110#section-15.5.5",
  "title": "Not Found",
  "status": 404,
  "detail": "Resource not found"
}
```

### 500 Internal Server Error

```json
{
  "type": "https://tools.ietf.org/html/rfc9110#section-15.6.1",
  "title": "Internal Server Error",
  "status": 500,
  "detail": "An unexpected error occurred"
}
```

## Rate Limiting

- Rate limit: 100 requests per minute per API key
- Headers returned with each request:
  - `X-RateLimit-Limit`: 100
  - `X-RateLimit-Remaining`: 95
  - `X-RateLimit-Reset`: 1642684200

## Pagination

All list endpoints support pagination:

- `page` (default: 1)
- `pageSize` (default: 10, max: 100)

## Swagger/OpenAPI

Access the interactive API documentation at:

```
https://api.jobsite.com/swagger
```
