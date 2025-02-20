---
seotitle: API Schemas – Path, Query, and Body parameters
seodesc: See how to design API schemas for your Go based backend application using Encore.
title: API Schemas
subtitle: How to design schemas for your APIs
lang: go
---
APIs in Encore are regular functions with request and response data types.
These types are structs (or pointers to structs) with optional field tags, which Encore uses to encode API requests to HTTP messages. The same struct can be used for requests and responses, but the `query` tag is ignored when generating responses.

All tags except `json` are ignored for nested tags, which means you can only define
`header` and `query` parameters for root level fields.

For example, this struct:
```go
type NestedRequestResponse struct {
	Header string `header:"X-Header"`// this field will be read from the http header
	Query  string `query:"query"`// this field will be read from the query string
	Body1  string `json:"body1"`
	Nested struct {
	    Header2 string `header:"X-Header2"`// this field will be read from the body
		Query2  string `query:"query2"`// this field will be read from the body
		Body2   string `json:"body2"`
    } `json:"nested"`
}
```

Would be unmarshalled from this request:

```output
POST /example?query=a%20query HTTP/1.1
Content-Type: application/json
X-Header: A header

{
   "body1": "a body",
   "nested": {
      "Header2": "not a header",
      "Query2": "not a query",
      "body2": "a nested body"
   }
}

```

And marshalled to this response:

```output
HTTP/1.1 200 OK
Content-Type: application/json
X-Header: A header

{
   "Query": "not a query",
   "body1": "a body",
   "nested": {
      "Header2": "not a header",
      "Query2": "not a query",
      "body2": "a nested body"
   }
}

```

## Path parameters

Path parameters are specified by the `path` field in the `//encore:api` annotation.
To specify a placeholder variable, use `:name` and add a function parameter with the same name to the function signature.
Encore parses the incoming request URL and makes sure it matches the type of the parameter. The last segment of the path
can be parsed as a wildcard parameter by using `*name` with a matching function parameter.

```go
// GetBlogPost retrieves a blog post by id.
//encore:api public method=GET path=/blog/:id/*path
func GetBlogPost(ctx context.Context, id int, path string) (*BlogPost, error) {
    // Use id to query database...
}
```

### Fallback routes

Encore supports defining fallback routes that will be called if no other endpoint matches the request,
using the syntax `path=/!fallback`.

This is often useful when migrating an existing backend service over to Encore, as it allows you to gradually
migrate endpoints over to Encore while routing the remaining endpoints to the existing HTTP router using
a raw endpoint with a fallback route.

For example:

```go
//encore:service
type Service struct {
	oldRouter *gin.Engine // existing HTTP router
}

// Route all requests to the existing HTTP router if no other endpoint matches.
//encore:api public raw path=/!fallback
func (s *Service) Fallback(w http.ResponseWriter, req *http.Request) {
    s.oldRouter.ServeHTTP(w, req)
}
```

## Headers

Headers are defined by the `header` field tag, which can be used in both request and response data types. The tag name is used to translate between the struct field and http headers.
In the example below, the `Language` field of `ListBlogPost` will be fetched from the
`Accept-Language` HTTP header.

```go
type ListBlogPost struct {
    Language string `header:"Accept-Language"`
    Author      string // Not a header
}
```

### Cookies

Cookies can be set in the response by using the `header` tag with the `Set-Cookie` header name.

```go
type LoginResponse struct {
    SessionID string `header:"Set-Cookie"`
}

//encore:api public method=POST path=/login
func Login(ctx context.Context) (*LoginResponse, error) {
    return &LoginResponse{SessionID: "session=123"}, nil
}
````

The cookies can then be read using e.g. [structured auth data](/docs/go/develop/auth#accepting-structured-auth-information). 

## Query parameters

For `GET`, `HEAD` and `DELETE` requests, parameters are read from the query string by default.
The query parameter name defaults to the [snake-case](https://en.wikipedia.org/wiki/Snake_case)
encoded name of the corresponding struct field (e.g. BlogPost becomes blog_post).

The `query` field tag can be used
to parse a field from the query string for other HTTP methods (e.g. POST) and to override the default parameter name. 

Query strings are not supported in HTTP responses and therefore `query` tags in response types are ignored.

In the example below, the `PageLimit` field will be read from the `limit` query
parameter, whereas the `Author` field will be parsed from the query string (as `author`) only if the method of
the request is `GET`, `HEAD` or `DELETE`.

```go
type ListBlogPost struct {
    PageLimit  int `query:"limit"` // always a query parameter
    Author     string              // query if GET, HEAD or DELETE, otherwise body parameter
}
```

## Body parameters

Encore will default to reading request parameters from the body (as JSON) for all HTTP methods except `GET`, `HEAD` or
`DELETE`. The name of the body parameter defaults to the field name, but can be overridden by the
`json` tag. Response fields will be serialized as JSON in the HTTP body unless the `header` tag is set.

There is no tag to force a field to be read from the body, as some infrastructure entities
do not support body content in `GET`, `HEAD` or `DELETE` requests.

```go
type CreateBlogPost struct {
    Subject    string `json:"limit"` // query if GET, HEAD or DELETE, otherwise body parameter
    Author     string                // query if GET, HEAD or DELETE, otherwise body parameter
}
```

## Supported types
The table below lists the data types supported by each HTTP message location.

| Type            | Header | Path | Query | Body |
| --------------- | ------ | ---- | ----- | ---- |
| bool            | X      | X    | X     | X    |
| numeric         | X      | X    | X     | X    |
| string          | X      | X    | X     | X    |
| time.Time       | X      | X    | X     | X    |
| uuid.UUID       | X      | X    | X     | X    |
| json.RawMessage | X      | X    | X     | X    |
| list            |        |      | X     | X    |
| struct          |        |      |       | X    |
| map             |        |      |       | X    |
| pointer         |        |      |       | X    |

## Raw endpoints

In some cases you may need to fulfill an API schema that is defined by someone else, for instance when you want to accept webhooks.
This often requires you to parse custom HTTP headers and do other low-level things that Encore usually lets you skip.

For these circumstances Encore lets you define raw endpoints. Raw endpoints operate at a lower abstraction level, giving you access to the underlying HTTP request.

Learn more in the [raw endpoints documentation](/docs/go/primitives/raw-endpoints).

## Sensitive data

Encore's built-in tracing functionality automatically captures request and response payloads
to simplify debugging. That's not desirable if a request or response payload contains sensitive data, such
as API keys or personally identifiable information (PII).

For those use cases Encore supports marking a field as sensitive using the struct tag `encore:"sensitive"`.
Encore's tracing system will automatically redact fields tagged as sensitive. This works for both individual
values as well as nested fields.

Note that inputs to [auth handlers](/docs/go/develop/auth) are automatically marked as sensitive and are always redacted.

Raw endpoints lack a schema, which means there's no way to add a struct tag to mark certain data as sensitive.
For this reason Encore supports tagging the whole API endpoint as sensitive by adding `sensitive` to the `//encore:api` annotation.
This will cause the whole request and response payload to be redacted, including all request and response headers.

<Callout type="info">

The `encore:"sensitive"` tag is ignored for local development environments to make development and debugging with the Local Development Dashboard easier.

</Callout>


## Example

```go
package blog // service name
import (
	"time"
	"encore.dev/types/uuid"
)

type Updates struct {
	Author      string `json:"author,omitempty"`
	PublishTime time.Time `json:"publish_time,omitempty"`
}

// BatchUpdateParams is the request data for the BatchUpdate endpoint.
type BatchUpdateParams struct {
	Requester     string    `header:"X-Requester"`
	RequestTime   time.Time `header:"X-Request-Time"`
	CurrentAuthor string    `query:"author"`
	Updates       *Updates  `json:"updates"`
	MySecretKey   string    `encore:"sensitive"`
}

// BatchUpdateResponse is the response data for the BatchUpdate endpoint.
type BatchUpdateResponse struct {
	ServedBy   string       `header:"X-Served-By"`
	UpdatedIDs []uuid.UUID  `json:"updated_ids"`
}

//encore:api public method=POST path=/section/:sectionID/posts
func BatchUpdate(ctx context.Context, sectionID string, params *BatchUpdateParams) (*BatchUpdateResponse, error) {
	// Update blog posts for section
	return &BatchUpdateResponse{ServedBy: hostname, UpdatedIDs: ids}, nil
}

```
