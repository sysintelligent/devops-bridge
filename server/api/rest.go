package api

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/sysintelligent/bdc-bridge/server/auth"
	"github.com/sysintelligent/bdc-bridge/server/kubernetes"
)

// RESTHandler handles REST API requests
type RESTHandler struct {
	k8sClient   *kubernetes.Client
	authService *auth.Service
	routes      map[string]http.HandlerFunc
}

// NewRESTHandler creates a new REST API handler
func NewRESTHandler(k8sClient *kubernetes.Client, authService *auth.Service) http.Handler {
	h := &RESTHandler{
		k8sClient:   k8sClient,
		authService: authService,
		routes:      make(map[string]http.HandlerFunc),
	}

	// Register routes
	h.routes["GET /applications"] = h.handleGetApplications
	h.routes["POST /applications"] = h.handleCreateApplication
	h.routes["GET /applications/{name}"] = h.handleGetApplication
	h.routes["PUT /applications/{name}"] = h.handleUpdateApplication
	h.routes["DELETE /applications/{name}"] = h.handleDeleteApplication
	h.routes["GET /settings"] = h.handleGetSettings
	h.routes["PUT /settings"] = h.handleUpdateSettings

	return h
}

// ServeHTTP implements the http.Handler interface
func (h *RESTHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// Set common headers
	w.Header().Set("Content-Type", "application/json")

	// Authenticate request
	user, err := h.authService.AuthenticateRequest(r)
	if err != nil {
		http.Error(w, `{"error":"Unauthorized"}`, http.StatusUnauthorized)
		return
	}

	// Check if user has permission to access the resource
	if !h.authService.HasPermission(user, r.Method, r.URL.Path) {
		http.Error(w, `{"error":"Forbidden"}`, http.StatusForbidden)
		return
	}

	// Find route handler
	path := strings.TrimPrefix(r.URL.Path, "/")
	routeKey := r.Method + " /" + path
	for pattern, handler := range h.routes {
		if matchRoute(pattern, routeKey) {
			handler(w, r)
			return
		}
	}

	// Route not found
	http.Error(w, `{"error":"Not Found"}`, http.StatusNotFound)
}

// matchRoute checks if a route pattern matches a route key
func matchRoute(pattern, key string) bool {
	// Simple implementation for demonstration purposes
	// In a real implementation, this would use a proper router
	patternParts := strings.Split(pattern, "/")
	keyParts := strings.Split(key, "/")

	if len(patternParts) != len(keyParts) {
		return false
	}

	for i, part := range patternParts {
		if strings.HasPrefix(part, "{") && strings.HasSuffix(part, "}") {
			// This is a path parameter, it matches any value
			continue
		}
		if part != keyParts[i] {
			return false
		}
	}

	return true
}

// handleGetApplications handles GET /applications
func (h *RESTHandler) handleGetApplications(w http.ResponseWriter, r *http.Request) {
	// Get applications from Kubernetes
	apps, err := h.k8sClient.GetApplications()
	if err != nil {
		http.Error(w, `{"error":"Failed to get applications"}`, http.StatusInternalServerError)
		return
	}

	// Return applications as JSON
	json.NewEncoder(w).Encode(apps)
}

// handleCreateApplication handles POST /applications
func (h *RESTHandler) handleCreateApplication(w http.ResponseWriter, r *http.Request) {
	// Parse request body
	var app kubernetes.Application
	if err := json.NewDecoder(r.Body).Decode(&app); err != nil {
		http.Error(w, `{"error":"Invalid request body"}`, http.StatusBadRequest)
		return
	}

	// Create application in Kubernetes
	if err := h.k8sClient.CreateApplication(&app); err != nil {
		http.Error(w, `{"error":"Failed to create application"}`, http.StatusInternalServerError)
		return
	}

	// Return success
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(app)
}

// handleGetApplication handles GET /applications/{name}
func (h *RESTHandler) handleGetApplication(w http.ResponseWriter, r *http.Request) {
	// Extract application name from URL
	name := extractPathParam(r.URL.Path, "applications")

	// Get application from Kubernetes
	app, err := h.k8sClient.GetApplication(name)
	if err != nil {
		http.Error(w, `{"error":"Application not found"}`, http.StatusNotFound)
		return
	}

	// Return application as JSON
	json.NewEncoder(w).Encode(app)
}

// handleUpdateApplication handles PUT /applications/{name}
func (h *RESTHandler) handleUpdateApplication(w http.ResponseWriter, r *http.Request) {
	// Extract application name from URL
	name := extractPathParam(r.URL.Path, "applications")

	// Parse request body
	var app kubernetes.Application
	if err := json.NewDecoder(r.Body).Decode(&app); err != nil {
		http.Error(w, `{"error":"Invalid request body"}`, http.StatusBadRequest)
		return
	}

	// Update application in Kubernetes
	if err := h.k8sClient.UpdateApplication(name, &app); err != nil {
		http.Error(w, `{"error":"Failed to update application"}`, http.StatusInternalServerError)
		return
	}

	// Return success
	json.NewEncoder(w).Encode(app)
}

// handleDeleteApplication handles DELETE /applications/{name}
func (h *RESTHandler) handleDeleteApplication(w http.ResponseWriter, r *http.Request) {
	// Extract application name from URL
	name := extractPathParam(r.URL.Path, "applications")

	// Delete application from Kubernetes
	if err := h.k8sClient.DeleteApplication(name); err != nil {
		http.Error(w, `{"error":"Failed to delete application"}`, http.StatusInternalServerError)
		return
	}

	// Return success
	w.WriteHeader(http.StatusNoContent)
}

// handleGetSettings handles GET /settings
func (h *RESTHandler) handleGetSettings(w http.ResponseWriter, r *http.Request) {
	// Placeholder for getting settings
	settings := map[string]interface{}{
		"version":      "0.1.0",
		"clusterName":  "default",
		"syncInterval": 300,
	}

	// Return settings as JSON
	json.NewEncoder(w).Encode(settings)
}

// handleUpdateSettings handles PUT /settings
func (h *RESTHandler) handleUpdateSettings(w http.ResponseWriter, r *http.Request) {
	// Parse request body
	var settings map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&settings); err != nil {
		http.Error(w, `{"error":"Invalid request body"}`, http.StatusBadRequest)
		return
	}

	// Placeholder for updating settings
	// In a real implementation, this would update settings in a database or config file

	// Return success
	json.NewEncoder(w).Encode(settings)
}

// extractPathParam extracts a path parameter from a URL path
func extractPathParam(path, prefix string) string {
	parts := strings.Split(strings.TrimPrefix(path, "/"), "/")
	if len(parts) < 2 || parts[0] != prefix {
		return ""
	}
	return parts[1]
}
