package auth

import (
	"context"
	"errors"
	"net/http"
	"strings"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
)

// User represents an authenticated user
type User struct {
	ID      string
	Name    string
	Email   string
	Groups  []string
	IsAdmin bool
	Token   string
}

// Service provides authentication and authorization services
type Service struct {
	// In a real implementation, this would have connections to OAuth providers,
	// a database for user information, etc.
}

// NewService creates a new auth service
func NewService() *Service {
	return &Service{}
}

// AuthenticateRequest authenticates an HTTP request
func (s *Service) AuthenticateRequest(r *http.Request) (*User, error) {
	// Get the Authorization header
	authHeader := r.Header.Get("Authorization")
	if authHeader == "" {
		return nil, errors.New("no authorization header")
	}

	// Check if it's a Bearer token
	if !strings.HasPrefix(authHeader, "Bearer ") {
		return nil, errors.New("invalid authorization header format")
	}

	// Extract the token
	token := strings.TrimPrefix(authHeader, "Bearer ")
	if token == "" {
		return nil, errors.New("empty token")
	}

	// In a real implementation, this would validate the token with an OAuth provider
	// For now, we'll just create a dummy user for demonstration purposes
	if token == "demo-token" {
		return &User{
			ID:      "user-1",
			Name:    "Demo User",
			Email:   "demo@example.com",
			Groups:  []string{"users"},
			IsAdmin: false,
			Token:   token,
		}, nil
	} else if token == "admin-token" {
		return &User{
			ID:      "admin-1",
			Name:    "Admin User",
			Email:   "admin@example.com",
			Groups:  []string{"users", "admins"},
			IsAdmin: true,
			Token:   token,
		}, nil
	}

	return nil, errors.New("invalid token")
}

// HasPermission checks if a user has permission to access a resource
func (s *Service) HasPermission(user *User, method, path string) bool {
	// If the user is an admin, they have access to everything
	if user.IsAdmin {
		return true
	}

	// For demonstration purposes, we'll implement a simple RBAC system
	// In a real implementation, this would be more sophisticated

	// Public endpoints that anyone can access
	if method == http.MethodGet && (path == "/health" || path == "/version") {
		return true
	}

	// User can read applications
	if method == http.MethodGet && strings.HasPrefix(path, "/applications") {
		return true
	}

	// User can read settings
	if method == http.MethodGet && path == "/settings" {
		return true
	}

	// All other operations require admin privileges
	return false
}

// GRPCAuthInterceptor creates a gRPC interceptor for authentication
func GRPCAuthInterceptor(authService *Service) grpc.UnaryServerInterceptor {
	return func(ctx context.Context, req interface{}, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (interface{}, error) {
		// Get metadata from context
		md, ok := metadata.FromIncomingContext(ctx)
		if !ok {
			return nil, status.Errorf(codes.Unauthenticated, "metadata is not provided")
		}

		// Get authorization token
		authHeader, ok := md["authorization"]
		if !ok || len(authHeader) == 0 {
			return nil, status.Errorf(codes.Unauthenticated, "authorization token is not provided")
		}

		// Check if it's a Bearer token
		token := authHeader[0]
		if !strings.HasPrefix(token, "Bearer ") {
			return nil, status.Errorf(codes.Unauthenticated, "invalid authorization header format")
		}

		// Extract the token
		token = strings.TrimPrefix(token, "Bearer ")
		if token == "" {
			return nil, status.Errorf(codes.Unauthenticated, "empty token")
		}

		// In a real implementation, this would validate the token with an OAuth provider
		// For now, we'll just create a dummy user for demonstration purposes
		var user *User
		if token == "demo-token" {
			user = &User{
				ID:      "user-1",
				Name:    "Demo User",
				Email:   "demo@example.com",
				Groups:  []string{"users"},
				IsAdmin: false,
				Token:   token,
			}
		} else if token == "admin-token" {
			user = &User{
				ID:      "admin-1",
				Name:    "Admin User",
				Email:   "admin@example.com",
				Groups:  []string{"users", "admins"},
				IsAdmin: true,
				Token:   token,
			}
		} else {
			return nil, status.Errorf(codes.Unauthenticated, "invalid token")
		}

		// Check if the user has permission to access the method
		if !hasPermissionForMethod(user, info.FullMethod) {
			return nil, status.Errorf(codes.PermissionDenied, "permission denied")
		}

		// Add the user to the context
		ctx = context.WithValue(ctx, "user", user)

		// Call the handler
		return handler(ctx, req)
	}
}

// hasPermissionForMethod checks if a user has permission to access a gRPC method
func hasPermissionForMethod(user *User, method string) bool {
	// If the user is an admin, they have access to everything
	if user.IsAdmin {
		return true
	}

	// For demonstration purposes, we'll implement a simple RBAC system
	// In a real implementation, this would be more sophisticated

	// Public endpoints that anyone can access
	if strings.HasSuffix(method, "Health") || strings.HasSuffix(method, "Version") {
		return true
	}

	// User can read applications
	if strings.HasSuffix(method, "GetApplications") || strings.HasSuffix(method, "GetApplication") {
		return true
	}

	// User can read settings
	if strings.HasSuffix(method, "GetSettings") {
		return true
	}

	// All other operations require admin privileges
	return false
}
