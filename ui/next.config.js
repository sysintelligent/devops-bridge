/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  output: 'standalone',
  images: {
    domains: [], // Add any image domains you need here
  },
  // Optimize for production
  poweredByHeader: false,
  compress: true,
  generateEtags: true,
  // Proxy API requests to the Go backend
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: 'http://localhost:8080/api/:path*',
      },
    ]
  },
  // Environment variables
  env: {
    API_URL: process.env.API_URL || 'http://localhost:8080',
    GRPC_URL: process.env.GRPC_URL || 'localhost:9090',
  },
}

module.exports = nextConfig 