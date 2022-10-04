// Code generated by encore. DO NOT EDIT.
//
// The contents of this file are generated from the structs used in
// conjunction with Encore's `config.Load[T]()` function. This file
// automatically be regenerated if the data types within the struct
// are changed.
//
// For more information about this file, see:
// https://encore.dev/docs/develop/config
package svc

// #Meta contains metadata about the running Encore application.
// The values in this struct will be injected by Encore upon deployment and can be
// referenced from other config values for example when configuring a callback URL:
//    CallbackURL: "\(#Meta.APIBaseURL)/webhooks.Handle`"
#Meta: {
	APIBaseURL: string @tag(APIBaseURL) // The base URL which can be used to call the API of this running application.
	Environment: {
		Name:  string                                              @tag(EnvName)   // The name of this environment
		Type:  "production" | "development" | "ephemeral" | "test" @tag(EnvType)   // The type of environment that the application is running in
		Cloud: "aws" | "azure" | "gcp" | "encore" | "local"        @tag(CloudType) // The cloud provider that the application is running in
	}
}

// #Config is the top level configuration for the application and is generated
// from the Go types you've passed into `config.Load[T]()`. Encore uses a definition
// of this struct which is closed, such that the CUE tooling can any typos of field names.
// this definition is then immediately inlined, so any fields within it are expected
// as fields at the package level.
#Config: {
	HTTP: #ServerOptions // The options for the HTTP server
	TCP:  #ServerOptions // The options for the TCP server
	GRPC: #ServerOptions // The options for the GRPC server
}
#Config

// ServerOptions represent options for a server
#ServerOptions: {
	Enabled: bool   // Is this option enabled?
	Port:    uint32 // What port should we run on?
}
