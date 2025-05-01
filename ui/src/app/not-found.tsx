'use client'

import React from 'react'
import Link from 'next/link'

export default function NotFound() {
  return (
    <div className="flex h-screen flex-col items-center justify-center gap-4">
      <h1 className="text-4xl font-bold">404</h1>
      <p className="text-xl">Page not found</p>
      <p className="text-muted-foreground">The page you're looking for doesn't exist.</p>
      <Link href="/">
        <button className="rounded-md bg-primary px-4 py-2 text-primary-foreground hover:bg-primary/90">
          Go back home
        </button>
      </Link>
    </div>
  )
} 