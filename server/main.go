package main

import (
	"context"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/sysintelligent/devops-bridge/server/api"
	"github.com/sysintelligent/devops-bridge/server/auth"
	"github.com/sysintelligent/devops-bridge/server/kubernetes"
	"google.golang.org/grpc"
)

const (
	httpPort = 8080
	grpcPort = 9090
)

func main() {
	// Set up logger
	logger := log.New(os.Stdout, "DEVOPS-SERVER: ", log.LstdFlags|log.Lshortfile)
	logger.Println("Starting DevOps Bridge server...")

	// Initialize Kubernetes client
	k8sClient, err := kubernetes.NewClient()
	if err != nil {
		logger.Fatalf("Failed to create Kubernetes client: %v", err)
	}
	logger.Println("Kubernetes client initialized")

	// Initialize auth service
	authService := auth.NewService()
	logger.Println("Auth service initialized")

	// Create context that listens for the interrupt signal
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	// Start HTTP server
	httpServer := startHTTPServer(logger, k8sClient, authService)
	logger.Printf("HTTP server listening on port %d", httpPort)

	// Start gRPC server
	grpcServer := startGRPCServer(logger, k8sClient, authService)
	logger.Printf("gRPC server listening on port %d", grpcPort)

	// Wait for interrupt signal
	<-ctx.Done()
	logger.Println("Shutdown signal received")

	// Create a timeout context for graceful shutdown
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Shutdown HTTP server
	if err := httpServer.Shutdown(shutdownCtx); err != nil {
		logger.Printf("HTTP server shutdown error: %v", err)
	}

	// Shutdown gRPC server
	grpcServer.GracefulStop()

	logger.Println("Server shutdown complete")
}

func startHTTPServer(logger *log.Logger, k8sClient *kubernetes.Client, authService *auth.Service) *http.Server {
	// Create REST API handler
	apiHandler := api.NewRESTHandler(k8sClient, authService)

	// Create HTTP server
	mux := http.NewServeMux()
	mux.Handle("/api/", http.StripPrefix("/api", apiHandler))
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w, "OK")
	})

	server := &http.Server{
		Addr:    fmt.Sprintf(":%d", httpPort),
		Handler: mux,
	}

	// Start HTTP server in a goroutine
	go func() {
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatalf("HTTP server error: %v", err)
		}
	}()

	return server
}

func startGRPCServer(logger *log.Logger, k8sClient *kubernetes.Client, authService *auth.Service) *grpc.Server {
	// Create gRPC server
	server := grpc.NewServer(
		grpc.UnaryInterceptor(auth.GRPCAuthInterceptor(authService)),
	)

	// Register gRPC services
	api.RegisterGRPCServices(server, k8sClient)

	// Start gRPC server in a goroutine
	go func() {
		lis, err := net.Listen("tcp", fmt.Sprintf(":%d", grpcPort))
		if err != nil {
			logger.Fatalf("Failed to listen for gRPC: %v", err)
		}
		if err := server.Serve(lis); err != nil {
			logger.Fatalf("gRPC server error: %v", err)
		}
	}()

	return server
}
